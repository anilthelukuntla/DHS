import { LightningElement, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import getConfig from '@salesforce/apex/DHSROIDesignerController.getConfig';
import saveConfig from '@salesforce/apex/DHSROIDesignerController.saveConfig';
import getMergeFields from '@salesforce/apex/DHSROIDesignerController.getMergeFields';
import renderPreview from '@salesforce/apex/DHSROIDesignerController.renderPreview';
import getTemplateLeadTypes from '@salesforce/apex/DHSROIDesignerController.getTemplateLeadTypes';
import getTemplateCoverageTypes from '@salesforce/apex/DHSROIDesignerController.getTemplateCoverageTypes';
import html2canvasResource from '@salesforce/resourceUrl/html2canvas';
import jsPdfResource from '@salesforce/resourceUrl/jspdf_umd';

const PAGE_WIDTH = 794;
const PAGE_HEIGHT = 1123;
const SNAP = 8;

const TYPE_LABELS = {
    section: 'Title',
    text: 'Text',
    field: 'Field',
    table: 'Table',
    divider: 'Line',
    signature: 'Signature'
};

const DEFAULT_SIZES = {
    section: { width: 480, height: 56 },
    text: { width: 420, height: 96 },
    field: { width: 300, height: 42 },
    table: { width: 460, height: 150 },
    divider: { width: 500, height: 24 },
    signature: { width: 300, height: 64 }
};

export default class RoiDesigner extends LightningElement {
    @track elements = [];
    @track mergeFields = [];
    @track conditionDraft = { fieldPath: '', operator: 'is not blank', value: '' };
    @track tableConditionDraft = { rowIndex: '0', fieldPath: '', operator: 'is not blank', value: '' };
    editingConditionIndex = null;
    editingTableCondition = null;
    @track leadTypeOptions = [];
    @track coverageTypeOptions = [];
    tableModalOpen = false;
    htmlModalOpen = false;
    htmlDraft = '';
    selectedIds = [];
    fieldFilter = '';
    selectedLeadType = '';
    selectedCoverageType = '';
    statusMessage = '';
    activeTool = 'select';
    snapEnabled = true;
    leftPanelCollapsed = false;
    rightPanelCollapsed = false;
    pageScale = 1;
    draggingType = '';
    interaction = null;
    pdfLibrariesLoaded = false;
    resizeObserver;

    scopeOptions = [
        { label: 'Case / Subject', value: 'case' },
        { label: 'Lead / Item', value: 'lead' }
    ];

    alignmentOptions = [
        { label: 'Left', value: 'left' },
        { label: 'Center', value: 'center' },
        { label: 'Right', value: 'right' },
        { label: 'Justify', value: 'justify' }
    ];

    conditionOptions = [
        { label: 'Is not blank', value: 'is not blank' },
        { label: 'Is blank', value: 'is blank' },
        { label: 'Equals', value: 'equals' },
        { label: 'Not equals', value: 'not equals' },
        { label: 'Contains', value: 'contains' }
    ];

    conditionLogicOptions = [
        { label: 'All conditions', value: 'all' },
        { label: 'Any condition', value: 'any' }
    ];

    tableBorderStyleOptions = [
        { label: 'Solid', value: 'solid' },
        { label: 'Dashed', value: 'dashed' },
        { label: 'Dotted', value: 'dotted' },
        { label: 'Double', value: 'double' },
        { label: 'No border', value: 'none' }
    ];

    connectedCallback() {
        this.loadMetadata();
    }

    renderedCallback() {
        this.renderElementContent();
        this.pageScale = 1;
    }

    disconnectedCallback() {
        if (this.resizeObserver) {
            this.resizeObserver.disconnect();
        }
    }

    observeWorkspace() {
        if (this.resizeObserver) {
            return;
        }
        const strip = this.template.querySelector('.page-strip');
        if (!strip || typeof ResizeObserver === 'undefined') {
            return;
        }
        this.resizeObserver = new ResizeObserver(() => this.updatePageScale());
        this.resizeObserver.observe(strip);
    }

    async loadMetadata() {
        try {
            this.mergeFields = await getMergeFields();
            const leadTypes = await getTemplateLeadTypes();
            this.leadTypeOptions = leadTypes;
            if (!this.selectedLeadType && leadTypes.length) {
                this.selectedLeadType = leadTypes[0].value;
            }
            await this.loadCoverageTypes();
            await this.loadBuilder();
            this.refreshElements();
        } catch (error) {
            this.setError(error);
        }
    }

    async loadCoverageTypes() {
        const coverageTypes = await getTemplateCoverageTypes({ leadType: this.selectedLeadType });
        this.coverageTypeOptions = coverageTypes;
        if (!coverageTypes.some((option) => option.value === this.selectedCoverageType)) {
            this.selectedCoverageType = coverageTypes.length ? coverageTypes[0].value : '';
        }
    }

    async loadBuilder() {
        try {
            if (!this.selectedLeadType || !this.selectedCoverageType) {
                this.statusMessage = 'Select Lead Type and Coverage Type.';
                return;
            }
            this.applyConfig(await getConfig({ leadType: this.selectedLeadType, coverageType: this.selectedCoverageType }));
            this.statusMessage = 'Designer loaded.';
        } catch (error) {
            this.setError(error);
        }
    }

    async saveBuilder() {
        try {
            await saveConfig({
                configJson: this.configJson,
                leadType: this.selectedLeadType,
                coverageType: this.selectedCoverageType
            });
            this.statusMessage = 'Saved.';
        } catch (error) {
            this.setError(error);
        }
    }

    async previewBuilder() {
        if (!this.selectedLeadType || !this.selectedCoverageType) {
            this.statusMessage = 'Select Lead Type and Coverage Type before previewing.';
            return;
        }

        const previewWindow = window.open('', '_blank');
        if (previewWindow) {
            previewWindow.document.write('<p style="font-family:Arial;padding:16px;">Preparing preview...</p>');
        }

        try {
            const html = await renderPreview({ configJson: this.configJson, caseId: null });
            const frame = this.template.querySelector('.preview-frame');
            if (frame) {
                frame.innerHTML = html;
            }
            if (previewWindow) {
                previewWindow.document.open();
                previewWindow.document.write(this.buildHtmlPreviewShell(html, 'Preparing PDF preview...'));
                previewWindow.document.close();
                try {
                    await this.loadPdfLibraries();
                    await this.openPdfPreview(previewWindow);
                } catch (pdfError) {
                    previewWindow.document.open();
                    previewWindow.document.write(this.buildHtmlPreviewShell(html, `PDF conversion failed: ${this.errorMessage(pdfError)}`));
                    previewWindow.document.close();
                }
            }
            this.statusMessage = 'Preview opened.';
        } catch (error) {
            this.setError(error);
            if (previewWindow) {
                previewWindow.document.open();
                previewWindow.document.write(this.buildHtmlPreviewShell('', this.errorMessage(error)));
                previewWindow.document.close();
            }
        }
    }

    async loadPdfLibraries() {
        if (this.pdfLibrariesLoaded) {
            return;
        }
        await Promise.all([
            loadScript(this, html2canvasResource),
            loadScript(this, jsPdfResource)
        ]);
        this.pdfLibrariesLoaded = true;
    }

    async openPdfPreview(previewWindow) {
        await new Promise((resolve) => window.setTimeout(resolve, 0));
        const documentNode = this.template.querySelector('.preview-frame .roi-preview-document');
        if (!documentNode) {
            throw new Error('ROI preview document was not created.');
        }

        const canvas = await window.html2canvas(documentNode, {
            backgroundColor: '#ffffff',
            scale: 2,
            useCORS: true
        });
        const pdf = new window.jspdf.jsPDF('p', 'pt', 'letter');
        const pageWidth = pdf.internal.pageSize.getWidth();
        const pageHeight = pdf.internal.pageSize.getHeight();
        const imageWidth = pageWidth;
        const imageHeight = canvas.height * imageWidth / canvas.width;
        const imageData = canvas.toDataURL('image/png');
        let position = 0;
        let heightLeft = imageHeight;

        pdf.addImage(imageData, 'PNG', 0, position, imageWidth, imageHeight);
        heightLeft -= pageHeight;
        while (heightLeft > 0) {
            position -= pageHeight;
            pdf.addPage();
            pdf.addImage(imageData, 'PNG', 0, position, imageWidth, imageHeight);
            heightLeft -= pageHeight;
        }

        const pdfUrl = URL.createObjectURL(pdf.output('blob'));
        previewWindow.location.href = pdfUrl;
        window.setTimeout(() => URL.revokeObjectURL(pdfUrl), 60000);
    }

    buildHtmlPreviewShell(bodyHtml, message) {
        return `<!doctype html>
<html>
<head>
    <title>ROI Preview</title>
    <style>
        body { background: #eef2f6; color: #000; font-family: Arial, sans-serif; margin: 0; }
        .preview-actions { background: #fff; border-bottom: 1px solid #d9e2ec; padding: 10px 14px; position: sticky; top: 0; z-index: 5; }
        .preview-actions button { background: #00799b; border: 0; color: #fff; cursor: pointer; padding: 8px 14px; }
        .preview-message { color: #607080; display: inline-block; margin-left: 12px; }
        .roi-preview-document { display:block; margin: 24px auto; width: 210mm; }
        .roi-preview-page { background: #fff; box-shadow: 0 6px 18px rgba(0,0,0,.18); display:block; margin: 0 auto 24px; position: relative; width: 210mm; }
        .roi-preview-block { box-sizing: border-box; overflow: hidden; padding: 6px; position: absolute; }
        .roi-preview-block p { margin: 0; }
        .roi-preview-table { border: var(--roi-table-border, 1px solid #999); border-collapse: collapse; width: 100%; }
        .roi-preview-table th, .roi-preview-table td { border: var(--roi-table-border, 1px solid #999); padding: var(--roi-table-padding, 4px) 8px; text-align: left; }
        .roi-signature span { border-top: 1px solid #111; display: inline-block; min-width: 220px; padding-top: 6px; }
        @media print {
            body { background: #fff; }
            .preview-actions { display: none; }
            .roi-preview-document { margin: 0; width: auto; }
            .roi-preview-page { box-shadow: none; margin: 0; page-break-inside: auto; }
        }
    </style>
</head>
<body>
    <div class="preview-actions">
        <button onclick="window.print()">Print / Save PDF</button>
        <span class="preview-message">${this.escapeHtml(message || '')}</span>
    </div>
    ${bodyHtml || '<div class="roi-preview-document"><div class="roi-preview-page"></div></div>'}
</body>
</html>`;
    }

    applyConfig(configJson) {
        const parsed = JSON.parse(this.stripBom(configJson || '{}'));
        const sourceElements = this.isTextOnlyTemplate
            ? (parsed.elements || []).filter((element) => element.type === 'text')
            : (parsed.elements || []);
        this.elements = sourceElements.map((element, index) => this.decorateElement(this.migrateElement(element, index)));
        if (!this.elements.length) {
            this.elements = this.defaultElements().map((element, index) => this.decorateElement(this.migrateElement(element, index)));
        }
        this.selectedIds = this.elements.length ? [this.elements[0].id] : [];
    }

    migrateElement(element, index) {
        const type = this.isTextOnlyTemplate ? 'text' : (TYPE_LABELS[element.type] ? element.type : 'text');
        const size = DEFAULT_SIZES[type] || DEFAULT_SIZES.text;
        const page = Number(element.page || element.pageNumber || 1);
        const legacyY = 72 + (index * 88) % 850;
        return {
            ...this.createElement(type, 72, legacyY, page),
            ...element,
            type,
            page,
            x: this.numberOrDefault(element.x, 72),
            y: this.numberOrDefault(element.y, legacyY),
            width: this.numberOrDefault(element.width, size.width),
            height: this.numberOrDefault(element.height, size.height),
            leadType: element.leadType || this.selectedLeadType,
            coverageType: element.coverageType || this.selectedCoverageType,
            conditionLogic: element.conditionLogic || 'all',
            conditions: element.conditions || [],
            fields: element.fields || [],
            tableRows: this.normalizeTableRows(element.tableRows, element.fields || []),
            tableBorderStyle: element.tableBorderStyle || 'solid',
            tableBorderWidth: this.numberOrDefault(element.tableBorderWidth, 1),
            tableBorderColor: element.tableBorderColor || '#999999',
            tableCellPadding: this.numberOrDefault(element.tableCellPadding, 4),
            tokens: element.tokens || []
        };
    }

    defaultElements() {
        if (this.isTextOnlyTemplate) {
            const label = this.selectedLeadType === 'PAEI' ? 'PAEI text' : 'Disclaimer text';
            return [
                {
                    id: `${this.selectedLeadType.toLowerCase()}-text`,
                    type: 'text',
                    text: label,
                    scope: 'case',
                    alignment: 'left',
                    fontSize: 13,
                    bold: false,
                    page: 1,
                    x: 72,
                    y: 72,
                    width: 560,
                    height: 120,
                    conditions: []
                }
            ];
        }
        return [
            {
                id: 'section-summary',
                type: 'section',
                text: 'REPORT OF INVESTIGATION',
                scope: 'case',
                alignment: 'center',
                fontSize: 18,
                bold: true,
                x: 130,
                y: 80,
                width: 560,
                height: 50,
                page: 1
            },
            {
                id: 'lead-notes',
                type: 'text',
                text: '<p>Lead {{Lead: Item Number}}: {{Lead: Investigators Notes}}</p>',
                scope: 'lead',
                alignment: 'left',
                fontSize: 13,
                x: 72,
                y: 154,
                width: 640,
                height: 90,
                page: 1,
                tokens: [
                    { label: 'Lead: Item Number', fieldPath: 'DHS_Lead__c.Item_number__c' },
                    { label: 'Lead: Investigators Notes', fieldPath: 'DHS_Lead__c.Investigators_Notes__c' }
                ],
                conditions: [
                    { fieldPath: 'DHS_Lead__c.Investigators_Notes__c', operator: 'is not blank', value: '' }
                ]
            }
        ];
    }

    get configJson() {
        return JSON.stringify({
            version: 2,
            name: 'ROI Page Designer',
            page: { width: PAGE_WIDTH, height: PAGE_HEIGHT, unit: 'px', size: 'Letter' },
            leadType: this.selectedLeadType,
            coverageType: this.selectedCoverageType,
            elements: this.elements.map((element) => this.cleanElement(element))
        }, null, 2);
    }

    get pages() {
        const maxPage = Math.max(1, ...this.elements.map((element) => Number(element.page || 1)));
        return Array.from({ length: maxPage }, (_, index) => {
            const number = index + 1;
            return {
                number,
                elements: this.elements.filter((element) => Number(element.page || 1) === number)
            };
        });
    }

    get designerClass() {
        const classes = ['designer'];
        if (this.leftPanelCollapsed) {
            classes.push('left-collapsed');
        }
        if (this.rightPanelCollapsed) {
            classes.push('right-collapsed');
        }
        if (this.activeTool === 'pan') {
            classes.push('pan-active');
        }
        return classes.join(' ');
    }

    get pageScaleNumber() {
        const scale = Number(this.pageScale);
        return Number.isFinite(scale) && scale > 0 ? scale : 1;
    }

    get pageScaleStyle() {
        return `--page-scale:${this.pageScaleNumber};`;
    }

    get leftPanelToggleLabel() {
        return this.leftPanelCollapsed ? '>' : '<';
    }

    get rightPanelToggleLabel() {
        return this.rightPanelCollapsed ? '<' : '>';
    }

    get leftPanelActionLabel() {
        return this.leftPanelCollapsed ? 'Show Insert' : 'Hide Insert';
    }

    get rightPanelActionLabel() {
        return this.rightPanelCollapsed ? 'Show Inspector' : 'Hide Inspector';
    }

    get rulerX() {
        return this.buildRuler(PAGE_WIDTH, false);
    }

    get rulerY() {
        return this.buildRuler(PAGE_HEIGHT, true);
    }

    buildRuler(limit, vertical) {
        const ticks = [];
        for (let value = 0; value <= limit; value += 48) {
            const major = value % 96 === 0;
            ticks.push({
                key: `${vertical ? 'y' : 'x'}-${value}`,
                label: major ? String(value) : '',
                className: major ? 'tick major' : 'tick',
                style: vertical ? `top:${value}px;` : `left:${value}px;`
            });
        }
        return ticks;
    }

    get selectedElement() {
        if (this.selectedIds.length !== 1) {
            return null;
        }
        const selected = this.elements.find((element) => element.id === this.selectedIds[0]);
        return selected ? { ...selected } : null;
    }

    get hasNoSelection() {
        return this.selectedIds.length === 0;
    }

    get selectToolClass() {
        return this.activeTool === 'select' ? 'active' : '';
    }

    get panToolClass() {
        return this.activeTool === 'pan' ? 'active' : '';
    }

    get snapButtonClass() {
        return this.snapEnabled ? 'active' : '';
    }

    get isTextOnlyTemplate() {
        return ['Disclaimer', 'PAEI'].includes(this.selectedLeadType);
    }

    get mergeFieldOptions() {
        return this.mergeFields.map((field) => ({ label: field.label, value: field.value }));
    }

    get conditionFieldOptions() {
        return this.mergeFields
            .filter((field) => field.scope === 'context')
            .map((field) => ({ label: field.label, value: field.value }));
    }

    get conditionActionLabel() {
        return this.editingConditionIndex === null || this.editingConditionIndex === undefined ? 'Add Condition' : 'Update Condition';
    }

    get isEditingCondition() {
        return !(this.editingConditionIndex === null || this.editingConditionIndex === undefined);
    }

    get filteredMergeFields() {
        const term = (this.fieldFilter || '').toLowerCase();
        const selected = this.selectedElement;
        const scopeRank = (field) => {
            if (selected?.scope === 'lead') {
                if (field.scope === 'lead') return 0;
                if (field.label.startsWith('Case:')) return 1;
                if (field.label.startsWith('Contact:')) return 2;
            }
            return 0;
        };
        return [...this.mergeFields]
            .filter((field) => !term || field.label.toLowerCase().includes(term) || field.value.toLowerCase().includes(term))
            .sort((a, b) => {
                const rank = scopeRank(a) - scopeRank(b);
                return rank || a.label.localeCompare(b.label);
            })
            .slice(0, 80);
    }

    addElementFromButton(event) {
        const type = event.currentTarget.dataset.type;
        if (!this.canAddBlockType(type)) {
            return;
        }
        this.addElement(type, 84, 84, this.pages.length);
    }

    addElement(type, x, y, page) {
        if (!this.canAddBlockType(type)) {
            return;
        }
        const element = this.decorateElement(this.createElement(type, x, y, page));
        this.elements = [...this.elements, element];
        this.selectedIds = [element.id];
    }

    canAddBlockType(type) {
        return !this.isTextOnlyTemplate || type === 'text';
    }

    createElement(type, x, y, page) {
        const size = DEFAULT_SIZES[type] || DEFAULT_SIZES.text;
        const base = {
            id: `${type}-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
            type,
            label: TYPE_LABELS[type] || type,
            text: type === 'section' ? 'New Report Section' : 'Write text here',
            scope: 'case',
            leadType: this.selectedLeadType,
            coverageType: this.selectedCoverageType,
            fieldPath: '',
            fields: [],
            tokens: [],
            alignment: type === 'section' ? 'center' : 'left',
            fontSize: type === 'section' ? 18 : 13,
            bold: type === 'section',
            italic: false,
            uppercase: false,
            conditionLogic: 'all',
            conditions: [],
            page,
            x: this.snap(x),
            y: this.snap(y),
            width: size.width,
            height: size.height
        };
        if (type === 'field') {
            base.fieldPath = 'DHS_Case__c.Case_Number__c';
            base.label = 'Case Number';
        }
        if (type === 'table') {
            base.fields = ['DHS_Case__c.Case_Number__c', 'DHS_Contact__r.First_Name__c', 'DHS_Contact__r.Last_Name__c'];
            base.tableRows = this.normalizeTableRows([], base.fields);
            base.tableBorderStyle = 'solid';
            base.tableBorderWidth = 1;
            base.tableBorderColor = '#999999';
            base.tableCellPadding = 4;
        }
        if (type === 'divider') {
            base.text = '';
            base.height = 20;
        }
        if (type === 'signature') {
            base.text = 'Investigator Signature';
            base.height = 64;
        }
        return base;
    }

    decorateElement(element) {
        const selected = this.selectedIds.includes(element.id);
        const primarySelected = this.selectedIds[0] === element.id;
        const clean = {
            ...element,
            page: Number(element.page || 1),
            x: this.numberOrDefault(element.x, 72),
            y: this.numberOrDefault(element.y, 72),
            width: this.numberOrDefault(element.width, 300),
            height: this.numberOrDefault(element.height, 60),
            fontSize: this.numberOrDefault(element.fontSize, 13),
            fields: element.fields || [],
            tableRows: this.normalizeTableRows(element.tableRows, element.fields || []),
            tableBorderStyle: element.tableBorderStyle || 'solid',
            tableBorderWidth: this.numberOrDefault(element.tableBorderWidth, 1),
            tableBorderColor: element.tableBorderColor || '#999999',
            tableCellPadding: this.numberOrDefault(element.tableCellPadding, 4),
            borderStyle: element.borderStyle || 'none',
            borderWidth: this.numberOrDefault(element.borderWidth, 0),
            borderColor: element.borderColor || '#999999',
            padding: this.numberOrDefault(element.padding, 6),
            tokens: element.tokens || [],
            conditions: (element.conditions || []).map((condition, index) => ({ ...condition, key: `${element.id}-condition-${index}` }))
        };
        clean.isField = clean.type === 'field';
        clean.isTable = clean.type === 'table';
        clean.hasText = clean.type === 'text' || clean.type === 'section' || clean.type === 'signature';
        clean.isLeadScope = clean.scope === 'lead';
        clean.conditionRows = clean.conditions.map((condition) => ({
            ...condition,
            display: `${this.fieldLabel(condition.fieldPath)} ${condition.operator} ${condition.value || ''}`.trim()
        }));
        clean.tableRowViews = clean.tableRows.map((row, index) => ({
            ...row,
            index,
            key: `${clean.id}-table-row-${index}`,
            label: this.rowLabel(row),
            conditionRows: (row.conditions || []).map((condition, conditionIndex) => ({
                ...condition,
                key: `${clean.id}-table-row-${index}-condition-${conditionIndex}`,
                display: `${this.fieldLabel(condition.fieldPath)} ${condition.operator} ${condition.value || ''}`.trim()
            }))
        }));
        clean.canvasClass = `page-element type-${clean.type}${primarySelected ? ' selected' : ''}${selected && !primarySelected ? ' multi-selected' : ''}`;
        clean.canvasStyle = [
            `left:${clean.x}px`,
            `top:${clean.y}px`,
            `width:${clean.width}px`,
            `height:${clean.height}px`,
            `font-size:${clean.fontSize}px`,
            `text-align:${clean.alignment || 'left'}`,
            clean.bold ? 'font-weight:700' : 'font-weight:400',
            clean.italic ? 'font-style:italic' : 'font-style:normal',
            clean.uppercase ? 'text-transform:uppercase' : 'text-transform:none',
            `border:${this.blockBorderCss(clean)}`,
            `padding:${clean.padding}px`
        ].join(';');
        clean.contentClass = `element-content type-${clean.type}`;
        return clean;
    }

    cleanElement(element) {
        const clone = { ...element };
        if (clone.scope === 'lead') {
            clone.leadType = this.selectedLeadType;
            clone.coverageType = this.selectedCoverageType;
        }
        [
            'isField',
            'isTable',
            'hasText',
            'isLeadScope',
            'conditionRows',
            'tableRowViews',
            'canvasClass',
            'canvasStyle',
            'contentClass'
        ].forEach((key) => delete clone[key]);
        clone.conditions = (clone.conditions || []).map((condition) => {
            const next = { ...condition };
            delete next.key;
            return next;
        });
        clone.tableRows = this.normalizeTableRows(clone.tableRows, clone.fields || []).map((row) => ({
            fieldPath: row.fieldPath,
            label: row.label || this.fieldLabel(row.fieldPath),
            conditions: (row.conditions || []).map((condition) => {
                const next = { ...condition };
                delete next.key;
                return next;
            }),
            conditionLogic: row.conditionLogic || 'all'
        }));
        if (clone.type === 'table') {
            clone.tableBorderStyle = clone.tableBorderStyle || 'solid';
            clone.tableBorderWidth = this.numberOrDefault(clone.tableBorderWidth, 1);
            clone.tableBorderColor = clone.tableBorderColor || '#999999';
            clone.tableCellPadding = this.numberOrDefault(clone.tableCellPadding, 4);
        }
        clone.borderStyle = clone.borderStyle || 'none';
        clone.borderWidth = this.numberOrDefault(clone.borderWidth, 0);
        clone.borderColor = clone.borderColor || '#999999';
        clone.padding = this.numberOrDefault(clone.padding, 6);
        return clone;
    }

    refreshElements() {
        this.elements = this.elements.map((element) => this.decorateElement(this.cleanElement(element)));
    }

    renderElementContent() {
        this.elements.forEach((element) => {
            const node = this.template.querySelector(`[data-render-id="${element.id}"]`);
            if (node) {
                node.innerHTML = this.localPreviewHtml(element);
            }
        });
    }

    localPreviewHtml(element) {
        if (element.type === 'field') {
            return `<strong>${this.escapeHtml(element.label || this.fieldLabel(element.fieldPath))}</strong>: ${this.escapeHtml(this.fieldLabel(element.fieldPath))}`;
        }
        if (element.type === 'table') {
            const rows = this.normalizeTableRows(element.tableRows, element.fields || [])
                .map((row) => `<tr><th>${this.escapeHtml(this.rowLabel(row))}</th><td>{{ ${this.escapeHtml(this.rowLabel(row).replace(/^[^:]+:\\s*/, ''))} }}</td></tr>`)
                .join('');
            const borderStyle = this.tableBorderCss(element);
            return `<table class="roi-preview-table" style="${borderStyle.table}"><tbody>${rows}</tbody></table>`;
        }
        if (element.type === 'divider') {
            return '<hr />';
        }
        if (element.type === 'signature') {
            return `<div class="roi-signature"><span>${this.sanitizeLocalHtml(element.text || 'Signature')}</span></div>`;
        }
        return this.sanitizeLocalHtml(element.text || element.label || '');
    }

    handlePaletteDrag(event) {
        this.draggingType = event.currentTarget.dataset.type;
        if (!this.canAddBlockType(this.draggingType)) {
            event.preventDefault();
            this.draggingType = '';
            return;
        }
        event.dataTransfer.setData('text/plain', this.draggingType);
    }

    allowDrop(event) {
        event.preventDefault();
    }

    handlePageDrop(event) {
        event.preventDefault();
        const type = event.dataTransfer.getData('text/plain') || this.draggingType;
        if (!TYPE_LABELS[type] || !this.canAddBlockType(type)) {
            return;
        }
        const pageNode = event.currentTarget;
        const rect = pageNode.getBoundingClientRect();
        this.addElement(
            type,
            (event.clientX - rect.left) / this.pageScaleNumber,
            (event.clientY - rect.top) / this.pageScaleNumber,
            Number(pageNode.dataset.page)
        );
        this.draggingType = '';
    }

    selectElement(event) {
        event.stopPropagation();
        const id = event.currentTarget.dataset.id;
        if (event.shiftKey || event.ctrlKey || event.metaKey) {
            this.selectedIds = this.selectedIds.includes(id)
                ? this.selectedIds.filter((item) => item !== id)
                : [...this.selectedIds, id];
        } else {
            this.selectedIds = [id];
        }
        this.refreshElements();
    }

    clearSelection(event) {
        if (event.target.classList.contains('page')) {
            this.selectedIds = [];
            this.refreshElements();
        }
    }

    startElementDrag(event) {
        if (this.activeTool !== 'select' || event.target.classList.contains('resize-handle')) {
            return;
        }
        event.preventDefault();
        event.stopPropagation();
        const id = event.currentTarget.dataset.id;
        if (!this.selectedIds.includes(id)) {
            this.selectedIds = [id];
        }
        this.interaction = {
            mode: 'move',
            startX: event.clientX,
            startY: event.clientY,
            originals: this.elements
                .filter((element) => this.selectedIds.includes(element.id))
                .map((element) => ({ id: element.id, x: element.x, y: element.y }))
        };
        this.refreshElements();
    }

    startResize(event) {
        event.preventDefault();
        event.stopPropagation();
        const id = event.currentTarget.dataset.id;
        const element = this.elements.find((item) => item.id === id);
        if (!element) {
            return;
        }
        this.selectedIds = [id];
        this.interaction = {
            mode: 'resize',
            id,
            startX: event.clientX,
            startY: event.clientY,
            width: element.width,
            height: element.height
        };
        this.refreshElements();
    }

    startPan(event) {
        if (this.activeTool !== 'pan' || event.button !== 0) {
            return;
        }
        event.preventDefault();
        this.interaction = {
            mode: 'pan',
            startX: event.clientX,
            startY: event.clientY,
            scrollLeft: event.currentTarget.scrollLeft,
            scrollTop: event.currentTarget.scrollTop
        };
    }

    handlePointerMove(event) {
        if (!this.interaction) {
            return;
        }
        if (this.interaction.mode === 'pan') {
            const strip = this.template.querySelector('.page-strip');
            if (strip) {
                strip.scrollLeft = this.interaction.scrollLeft - (event.clientX - this.interaction.startX);
                strip.scrollTop = this.interaction.scrollTop - (event.clientY - this.interaction.startY);
            }
            return;
        }
        const dx = (event.clientX - this.interaction.startX) / this.pageScaleNumber;
        const dy = (event.clientY - this.interaction.startY) / this.pageScaleNumber;
        if (this.interaction.mode === 'move') {
            this.elements = this.elements.map((element) => {
                const original = this.interaction.originals.find((item) => item.id === element.id);
                if (!original) {
                    return element;
                }
                return this.decorateElement({
                    ...this.cleanElement(element),
                    x: this.bound(this.snap(original.x + dx), 0, PAGE_WIDTH - element.width),
                    y: this.bound(this.snap(original.y + dy), 0, PAGE_HEIGHT - element.height)
                });
            });
        }
        if (this.interaction.mode === 'resize') {
            this.elements = this.elements.map((element) => {
                if (element.id !== this.interaction.id) {
                    return element;
                }
                return this.decorateElement({
                    ...this.cleanElement(element),
                    width: this.bound(this.snap(this.interaction.width + dx), 24, PAGE_WIDTH - element.x),
                    height: this.bound(this.snap(this.interaction.height + dy), 18, PAGE_HEIGHT - element.y)
                });
            });
        }
    }

    handlePointerUp() {
        this.interaction = null;
    }

    addPage() {
        this.addElement('text', 72, 72, this.pages.length + 1);
    }

    duplicateSelection() {
        const clones = this.elements
            .filter((element) => this.selectedIds.includes(element.id))
            .map((element) => this.decorateElement({
                ...this.cleanElement(element),
                id: `${element.type}-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
                x: this.bound(element.x + 24, 0, PAGE_WIDTH - element.width),
                y: this.bound(element.y + 24, 0, PAGE_HEIGHT - element.height)
            }));
        this.elements = [...this.elements, ...clones];
        this.selectedIds = clones.map((element) => element.id);
        this.refreshElements();
    }

    deleteSelection() {
        this.elements = this.elements.filter((element) => !this.selectedIds.includes(element.id));
        this.selectedIds = [];
        this.refreshElements();
    }

    setTool(event) {
        this.activeTool = event.currentTarget.dataset.tool;
    }

    toggleSnap() {
        this.snapEnabled = !this.snapEnabled;
    }

    toggleLeftPanel() {
        this.leftPanelCollapsed = !this.leftPanelCollapsed;
    }

    toggleRightPanel() {
        this.rightPanelCollapsed = !this.rightPanelCollapsed;
    }

    updatePageScale() {
        this.pageScale = 1;
    }

    updateSelected(event) {
        const field = event.currentTarget.dataset.field;
        const value = event.detail.value;
        if (field === 'fieldPath') {
            this.patchSelected({ fieldPath: value, label: this.fieldLabel(value) });
            return;
        }
        this.patchSelected({ [field]: value });
    }

    updateSelectedNumber(event) {
        const field = event.currentTarget.dataset.field;
        this.patchSelected({ [field]: Number(event.detail.value || 0) });
    }

    updateSelectedValue(event) {
        const field = event.currentTarget.dataset.field;
        this.patchSelected({ [field]: event.detail.value || event.target.value });
    }

    updateSelectedChecked(event) {
        this.patchSelected({ [event.currentTarget.dataset.field]: event.target.checked });
    }

    updateTableFields(event) {
        const fields = event.detail.value;
        const selected = this.selectedElement;
        this.patchSelected({ fields, tableRows: this.normalizeTableRows(selected?.tableRows || [], fields) });
    }

    openTableModal() {
        this.tableModalOpen = true;
        this.tableConditionDraft = { rowIndex: '0', fieldPath: '', operator: 'is not blank', value: '' };
    }

    closeTableModal() {
        this.tableModalOpen = false;
    }

    openHtmlModal() {
        const selected = this.selectedElement;
        if (!selected || !selected.hasText) {
            return;
        }
        this.htmlDraft = selected.text || '';
        this.htmlModalOpen = true;
    }

    closeHtmlModal() {
        this.htmlModalOpen = false;
    }

    updateHtmlDraft(event) {
        this.htmlDraft = event.target.value;
    }

    saveHtmlDraft() {
        this.patchSelected({ text: this.htmlDraft });
        this.htmlModalOpen = false;
    }

    updateTableConditionDraft(event) {
        const field = event.currentTarget.dataset.field;
        this.tableConditionDraft = {
            ...this.tableConditionDraft,
            [field]: event.detail.value
        };
    }

    addTableRowCondition() {
        const selected = this.selectedElement;
        if (!selected || selected.type !== 'table' || !this.tableConditionDraft.fieldPath) {
            return;
        }
        const rowIndex = Number(this.tableConditionDraft.rowIndex || 0);
        const tableRows = this.normalizeTableRows(selected.tableRows, selected.fields).map((row, index) => {
            if (index !== rowIndex) {
                return row;
            }
            return {
                ...row,
                conditions: [...(row.conditions || []), {
                    fieldPath: this.tableConditionDraft.fieldPath,
                    operator: this.tableConditionDraft.operator,
                    value: this.tableConditionDraft.value
                }]
            };
        });
        this.patchSelected({ tableRows });
        this.tableConditionDraft = { rowIndex: String(rowIndex), fieldPath: '', operator: 'is not blank', value: '' };
    }

    removeTableRowCondition(event) {
        const rowIndex = Number(event.currentTarget.dataset.rowIndex);
        const conditionIndex = Number(event.currentTarget.dataset.conditionIndex);
        const selected = this.selectedElement;
        const tableRows = this.normalizeTableRows(selected.tableRows, selected.fields).map((row, index) => {
            if (index !== rowIndex) {
                return row;
            }
            return {
                ...row,
                conditions: (row.conditions || []).filter((condition, currentIndex) => currentIndex !== conditionIndex)
            };
        });
        this.patchSelected({ tableRows });
    }

    patchSelected(patch) {
        this.elements = this.elements.map((element) => {
            if (!this.selectedIds.includes(element.id)) {
                return element;
            }
            return this.decorateElement({ ...this.cleanElement(element), ...patch });
        });
    }

    updateConditionDraft(event) {
        this.conditionDraft = {
            ...this.conditionDraft,
            [event.currentTarget.dataset.field]: event.detail.value
        };
    }

    addCondition() {
        if (!this.selectedIds.length || !this.conditionDraft.fieldPath) {
            return;
        }
        this.elements = this.elements.map((element) => {
            if (!this.selectedIds.includes(element.id)) {
                return element;
            }
            const clean = this.cleanElement(element);
            const conditions = [...(clean.conditions || [])];
            if (this.editingConditionIndex === null || this.editingConditionIndex === undefined) {
                conditions.push({ ...this.conditionDraft });
            } else {
                conditions[this.editingConditionIndex] = { ...this.conditionDraft };
            }
            return this.decorateElement({
                ...clean,
                conditions
            });
        });
        this.conditionDraft = { fieldPath: '', operator: 'is not blank', value: '' };
        this.editingConditionIndex = null;
    }

    editCondition(event) {
        const indexToEdit = Number(event.currentTarget.dataset.index);
        const selected = this.selectedElement;
        const condition = selected?.conditions?.[indexToEdit];
        if (!condition) {
            return;
        }
        this.editingConditionIndex = indexToEdit;
        this.conditionDraft = {
            fieldPath: condition.fieldPath || '',
            operator: condition.operator || 'is not blank',
            value: condition.value || ''
        };
    }

    cancelConditionEdit() {
        this.editingConditionIndex = null;
        this.conditionDraft = { fieldPath: '', operator: 'is not blank', value: '' };
    }

    removeCondition(event) {
        const indexToRemove = Number(event.currentTarget.dataset.index);
        this.elements = this.elements.map((element) => {
            if (!this.selectedIds.includes(element.id)) {
                return element;
            }
            const clean = this.cleanElement(element);
            return this.decorateElement({
                ...clean,
                conditions: clean.conditions.filter((condition, index) => index !== indexToRemove)
            });
        });
        if (this.editingConditionIndex === indexToRemove) {
            this.cancelConditionEdit();
        }
    }

    insertMergeField(event) {
        const fieldPath = event.currentTarget.dataset.value;
        const fieldLabel = this.fieldLabel(fieldPath);
        const selected = this.selectedElement;
        if (!selected) {
            return;
        }
        if (selected.type === 'field') {
            this.patchSelected({ fieldPath, label: fieldLabel });
            return;
        }
        if (selected.type === 'table') {
            const fields = [...selected.fields, fieldPath];
            this.patchSelected({ fields, tableRows: this.normalizeTableRows(selected.tableRows, fields) });
            return;
        }
        this.patchSelected({
            text: `${selected.text || ''}{{${fieldLabel}}}`,
            tokens: selected.tokens.some((token) => token.fieldPath === fieldPath)
                ? selected.tokens
                : [...selected.tokens, { label: fieldLabel, fieldPath }]
        });
    }

    handleFieldFilter(event) {
        this.fieldFilter = event.detail?.value ?? event.target?.value ?? '';
    }

    async handleTemplateLeadType(event) {
        this.selectedLeadType = event.detail.value;
        await this.loadCoverageTypes();
        await this.loadBuilder();
    }

    async handleTemplateCoverageType(event) {
        this.selectedCoverageType = event.detail.value;
        await this.loadBuilder();
    }

    fieldLabel(fieldPath) {
        const match = this.mergeFields.find((field) => field.value === fieldPath);
        if (match) {
            return match.label;
        }
        const lowerFieldPath = String(fieldPath || '').toLowerCase();
        const caseInsensitiveMatch = this.mergeFields.find((field) => String(field.value || '').toLowerCase() === lowerFieldPath);
        return caseInsensitiveMatch ? caseInsensitiveMatch.label : 'Choose Field';
    }

    rowLabel(row) {
        if (row?.label) {
            return row.label;
        }
        return this.fieldLabel(row?.fieldPath);
    }

    get tableRowOptions() {
        const selected = this.selectedElement;
        if (!selected || selected.type !== 'table') {
            return [];
        }
        return this.normalizeTableRows(selected.tableRows, selected.fields).map((row, index) => ({
            label: this.rowLabel(row),
            value: String(index)
        }));
    }

    normalizeTableRows(rows, fields) {
        const existingByField = new Map((rows || []).map((row) => [row.fieldPath, row]));
        return (fields || []).map((fieldPath) => {
            const existing = existingByField.get(fieldPath) || {};
            return {
                fieldPath,
                label: existing.label || this.fieldLabel(fieldPath),
                conditionLogic: existing.conditionLogic || 'all',
                conditions: existing.conditions || []
            };
        });
    }

    stripBom(value) {
        return String(value || '').replace(/^\uFEFF/, '');
    }

    tableBorderCss(element) {
        const style = element.tableBorderStyle || 'solid';
        const width = this.numberOrDefault(element.tableBorderWidth, 1);
        const color = this.safeColor(element.tableBorderColor || '#999999');
        const padding = this.numberOrDefault(element.tableCellPadding, 4);
        const border = style === 'none' || width === 0 ? '0' : `${width}px ${style} ${color}`;
        return {
            table: `border-collapse:collapse;--roi-table-border:${border};--roi-table-padding:${padding}px;`
        };
    }

    blockBorderCss(element) {
        const style = element.borderStyle || 'none';
        const width = this.numberOrDefault(element.borderWidth, 0);
        const color = this.safeColor(element.borderColor || '#999999');
        return style === 'none' || width === 0 ? '0' : `${width}px ${style} ${color}`;
    }

    safeColor(value) {
        const color = String(value || '').trim();
        return /^#[0-9a-fA-F]{6}$/.test(color) ? color : '#999999';
    }

    snap(value) {
        return this.snapEnabled ? Math.round(Number(value || 0) / SNAP) * SNAP : Math.round(Number(value || 0));
    }

    bound(value, min, max) {
        return Math.max(min, Math.min(max, value));
    }

    numberOrDefault(value, fallback) {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : fallback;
    }

    setError(error) {
        this.statusMessage = this.errorMessage(error);
    }

    errorMessage(error) {
        return error?.body?.message || error?.message || 'Something went wrong.';
    }

    sanitizeLocalHtml(value) {
        return String(value || '')
            .replace(/<script[\s\S]*?>[\s\S]*?<\/script>/gi, '')
            .replace(/\son[a-z]+\s*=\s*"[^"]*"/gi, '')
            .replace(/\son[a-z]+\s*=\s*'[^']*'/gi, '')
            .replace(/javascript\s*:/gi, '');
    }

    escapeHtml(value) {
        return String(value || '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }
}