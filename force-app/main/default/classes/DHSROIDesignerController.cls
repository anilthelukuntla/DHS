/**
 * @description Provides DHS ROI designer configuration, merge-field, and preview services.
 */
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveClassLength,PMD.ExcessiveParameterList,PMD.NcssCount,PMD.NcssMethodCount,PMD.NcssTypeCount,PMD.StdCyclomaticComplexity,PMD.UnusedMethod')
public with sharing class DHSROIDesignerController {
    private static final String CONFIG_TITLE = 'ROIBuilderConfig';
    private static final String CONFIG_FILE_NAME = 'ROIBuilderConfig.json';
    private static Map<String, Map<String, Schema.SObjectField>> fieldMapByObject = new Map<String, Map<String, Schema.SObjectField>>();
    private static Map<String, Map<String, String>> fieldApiByLowerByObject = new Map<String, Map<String, String>>();
    private static Map<String, String> labelByFieldPath = new Map<String, String>();
    private static Map<String, Schema.DescribeFieldResult> describeByFieldPath = new Map<String, Schema.DescribeFieldResult>();
    private static Map<String, Object> activeRenderContext = new Map<String, Object>();

    /**
     * @description Provides this DHS API member.

     */
    public class FieldOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String scope;

        /**
         * @description Provides this DHS API member.

         * @param label Method parameter.
         * @param value Method parameter.
         * @param scope Method parameter.
         */
        public FieldOption(String label, String value, String scope) {
            this.label = label;
            this.value = value;
            this.scope = scope;
        }
    }

    /**
     * @description Provides this DHS API member.

     */
    public class CaseOption {
        @AuraEnabled public Id value;
        @AuraEnabled public String label;

        /**
         * @description Provides this DHS API member.

         * @param value Method parameter.
         * @param label Method parameter.
         */
        public CaseOption(Id value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    /**
     * @description Provides this DHS API member.

     */
    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        /**
         * @description Provides this DHS API member.

         * @param label Method parameter.
         * @param value Method parameter.
         */
        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    private class ParsedTemplate {
        public List<Object> elements;
        public Integer maxPage;
        public Map<Integer, Integer> pageHeights;

        /**
         * @description Provides this DHS API member.

         * @param configJson Method parameter.
         */
        public ParsedTemplate(String configJson) {
            Map<String, Object> config = (Map<String, Object>) JSON.deserializeUntyped(configJson);
            elements = (List<Object>) config.get('elements');
            if (elements == null) {
                elements = new List<Object>();
            }
            maxPage = maxPage(elements);
            pageHeights = pageHeights(elements, maxPage);
        }
    }

    private class RenderCandidate implements Comparable {
        public Map<String, Object> element;
        public Integer x;
        public Integer y;
        public Integer height;

        /**
         * @description Provides this DHS API member.

         * @param source Method parameter.
         */
        public RenderCandidate(Map<String, Object> source) {
            element = source;
            x = getInteger(source, 'x', 72);
            y = getInteger(source, 'y', 72);
            height = getInteger(source, 'height', 60);
        }

        /**
         * @description Provides this DHS API member.

         * @param otherObject Method parameter.
         * @return The requested result.
         */
        public Integer compareTo(Object otherObject) {
            RenderCandidate other = (RenderCandidate) otherObject;
            if (y != other.y) {
                return y < other.y ? -1 : 1;
            }
            if (x != other.x) {
                return x < other.x ? -1 : 1;
            }
            return 0;
        }
    }

    private class FieldReference {
        public String objectName;
        public String fieldName;

        /**
         * @description Provides this DHS API member.

         * @param objectName Method parameter.
         * @param fieldName Method parameter.
         */
        public FieldReference(String objectName, String fieldName) {
            this.objectName = objectName;
            this.fieldName = fieldName;
        }
    }

    /**
     * @description Provides this DHS API member.
     * @param leadType Method parameter.
     * @param coverageType Method parameter.
     * @return The requested result.
     */
    @AuraEnabled(cacheable=true)
    public static String getConfig(String leadType, String coverageType) {
        return loadConfig(leadType, coverageType, true);
    }

    private static String loadConfig(String leadType, String coverageType, Boolean includeDefault) {
        Account isnAccount = getIsnAccount();
        String configTitle = configTitleFor(leadType, coverageType);
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :isnAccount.Id
            AND ContentDocument.Title = :configTitle
            WITH USER_MODE ORDER BY ContentDocument.CreatedDate DESC
            LIMIT 1
        ];

        if (links.isEmpty()) {
            return includeDefault ? defaultConfig(leadType, coverageType) : null;
        }

        List<ContentVersion> versions = [
            SELECT VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :links[0].ContentDocumentId
            AND IsLatest = true
            WITH USER_MODE LIMIT 1
        ];

        if (versions.isEmpty()) {
            return includeDefault ? defaultConfig(leadType, coverageType) : null;
        }

        return stripBom(versions[0].VersionData.toString());
    }

    /**
     * @description Provides this DHS API member.
     * @param configJson Method parameter.
     * @param leadType Method parameter.
     * @param coverageType Method parameter.
     * @return The requested result.
     */
    @AuraEnabled
    public static String saveConfig(String configJson, String leadType, String coverageType) {
        if (String.isBlank(configJson)) {
            throw new AuraHandledException('Configuration JSON cannot be blank.');
        }
        configJson = stripBom(configJson);
        if (String.isBlank(leadType) || String.isBlank(coverageType)) {
            throw new AuraHandledException('Select Lead Type and Coverage Type before saving.');
        }

        try {
            JSON.deserializeUntyped(configJson);
        } catch (Exception ex) {
            throw new AuraHandledException('Configuration JSON is invalid: ' + ex.getMessage());
        }

        Account isnAccount = getIsnAccount();
        String configTitle = configTitleFor(leadType, coverageType);
        String configFileName = configTitle + '.json';
        List<ContentDocumentLink> existingLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :isnAccount.Id
            AND ContentDocument.Title = :configTitle
            WITH USER_MODE ORDER BY ContentDocument.CreatedDate DESC
            LIMIT 1
        ];

        ContentVersion version = new ContentVersion(
            Title = configTitle,
            PathOnClient = configFileName,
            VersionData = Blob.valueOf(configJson)
        );

        if (existingLinks.isEmpty()) {
            version.FirstPublishLocationId = isnAccount.Id;
        } else {
            version.ContentDocumentId = existingLinks[0].ContentDocumentId;
        }

        Database.insert(version, AccessLevel.USER_MODE);
        return 'Saved';
    }

    /**
     * @description Provides this DHS API member.

     * @return The requested result.
     */
    public static String resetDefaultTemplates() {
        Account isnAccount = getIsnAccount();
        String titlePattern = CONFIG_TITLE + '%';
        List<ContentDocumentLink> existingLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :isnAccount.Id
            AND ContentDocument.Title LIKE :titlePattern WITH USER_MODE
        ];

        Set<Id> documentIds = new Set<Id>();
        for (ContentDocumentLink link : existingLinks) {
            documentIds.add(link.ContentDocumentId);
        }
        if (!documentIds.isEmpty()) {
            Database.delete([SELECT Id FROM ContentDocument WHERE Id IN :documentIds WITH USER_MODE ], AccessLevel.USER_MODE);
        }

        List<ContentVersion> versions = new List<ContentVersion>();
        Set<String> templateKeys = new Set<String>();
        for (PicklistOption leadTypeOption : getTemplateLeadTypes()) {
            for (PicklistOption coverageTypeOption : getTemplateCoverageTypes(leadTypeOption.value)) {
                String key = String.valueOf(leadTypeOption.value) + '|' + String.valueOf(coverageTypeOption.value);
                if (templateKeys.contains(key)) {
                    continue;
                }
                templateKeys.add(key);
                String configTitle = configTitleFor(leadTypeOption.value, coverageTypeOption.value);
                versions.add(new ContentVersion(
                    Title = configTitle,
                    PathOnClient = configTitle + '.json',
                    VersionData = Blob.valueOf(defaultConfig(leadTypeOption.value, coverageTypeOption.value)),
                    FirstPublishLocationId = isnAccount.Id
                ));
            }
        }

        if (!versions.isEmpty()) {
            Database.insert(versions, AccessLevel.USER_MODE);
        }

        return 'Deleted ' + documentIds.size() + ' saved templates and recreated ' + versions.size() + ' default templates.';
    }

    private static String stripBom(String value) {
        if (String.isBlank(value)) {
            return value;
        }
        return value.startsWith('\uFEFF') ? value.substring(1) : value;
    }

    @SuppressWarnings('PMD.ApexDoc')
    @AuraEnabled(cacheable=true)
    /**
     * @description Returns the available merge fields.
     * @return The available merge-field options.
     */
    public static List<FieldOption> getMergeFields() {
        List<FieldOption> options = new List<FieldOption>();
        options.addAll(getContextFieldOptions());
        options.addAll(getFieldOptions('DHS_Case__c', 'Case', 'case', 'DHS_Case__c'));
        options.addAll(getFieldOptions('DHS_Contact__c', 'Contact', 'case', 'DHS_Contact__r'));
        options.addAll(getFieldOptions('DHS_Lead__c', 'Lead', 'lead', 'DHS_Lead__c'));
        return options;
    }

    @SuppressWarnings('PMD.ApexDoc')
    @AuraEnabled(cacheable=true)
    /**
     * @description Searches DHS cases.
     * @param searchTerm Case search text.
     * @return Matching DHS cases.
     */
    public static List<CaseOption> searchCases(String searchTerm) {
        String term = String.isBlank(searchTerm) ? '%' : '%' + String.escapeSingleQuotes(searchTerm.trim()) + '%';
        List<CaseOption> options = new List<CaseOption>();
        for (DHS_Case__c c : [
            SELECT Id, Name, Case_Number__c, Customer_Case_Number__c, DHS_Contact__r.First_Name__c, DHS_Contact__r.Last_Name__c
            FROM DHS_Case__c
            WHERE Name LIKE :term
            OR Case_Number__c LIKE :term
            OR Customer_Case_Number__c LIKE :term
            WITH USER_MODE ORDER BY CreatedDate DESC
            LIMIT 25
        ]) {
            List<String> labelParts = new List<String>();
            if (String.isNotBlank(c.Case_Number__c)) {
                labelParts.add(c.Case_Number__c);
            }
            if (String.isNotBlank(c.Customer_Case_Number__c)) {
                labelParts.add(c.Customer_Case_Number__c);
            }
            if (c.DHS_Contact__r != null) {
                labelParts.add((String.valueOf(c.DHS_Contact__r.First_Name__c) + ' ' + String.valueOf(c.DHS_Contact__r.Last_Name__c)).trim());
            }
            if (labelParts.isEmpty()) {
                labelParts.add(c.Name);
            }
            options.add(new CaseOption(c.Id, String.join(labelParts, ' - ')));
        }
        return options;
    }

    @SuppressWarnings('PMD.ApexDoc')
    @AuraEnabled(cacheable=true)
    /**
     * @description Returns values for a picklist field.
     * @param fieldPath Field path to describe.
     * @return Available picklist values.
     */
    public static List<PicklistOption> getPicklistValues(String fieldPath) {
        List<PicklistOption> options = new List<PicklistOption>();
        Schema.DescribeFieldResult describeField = describeFieldPath(fieldPath);
        if (describeField == null || !describeField.isAccessible()) {
            return options;
        }

        Schema.DisplayType fieldType = describeField.getType();
        if (fieldType != Schema.DisplayType.Picklist && fieldType != Schema.DisplayType.MultiPicklist) {
            return options;
        }

        for (Schema.PicklistEntry entry : describeField.getPicklistValues()) {
            if (entry.isActive()) {
                options.add(new PicklistOption(entry.getLabel(), entry.getValue()));
            }
        }
        return options;
    }

    @SuppressWarnings('PMD.ApexDoc')
    @AuraEnabled(cacheable=true)
    /**
     * @description Returns configured template lead types.
     * @return Available template lead types.
     */
    public static List<PicklistOption> getTemplateLeadTypes() {
        List<PicklistOption> options = new List<PicklistOption>{
            new PicklistOption('Header', 'Header'),
            new PicklistOption('Disclaimer', 'Disclaimer'),
            new PicklistOption('PAEI', 'PAEI'),
            new PicklistOption('Summary', 'Summary'),
            new PicklistOption('Report Table', 'Report Table')
        };
        options.addAll(getActivePicklistOptions('DHS_Auto_Lead_Generation_Setting__c', 'Lead_Type__c'));
        return options;
    }

    @SuppressWarnings('PMD.ApexDoc')
    @AuraEnabled(cacheable=true)
    /**
     * @description Returns coverage types for a lead type.
     * @param leadType Selected lead type.
     * @return Available coverage types.
     */
    public static List<PicklistOption> getTemplateCoverageTypes(String leadType) {
        if (isCaseLevelTemplate(leadType)) {
            return new List<PicklistOption>{ new PicklistOption(leadType, leadType) };
        }

        List<PicklistOption> configuredOptions = new List<PicklistOption>();
        if (String.isNotBlank(leadType)) {
            for (AggregateResult result : [
                SELECT Coverage_Type__c coverageType
                FROM DHS_Auto_Lead_Generation_Setting__c
                WHERE Lead_Type__c = :leadType
                AND Coverage_Type__c != null
                WITH USER_MODE GROUP BY Coverage_Type__c
                ORDER BY Coverage_Type__c
            ]) {
                String coverageType = String.valueOf(result.get('coverageType'));
                configuredOptions.add(new PicklistOption(coverageType, coverageType));
            }
        }
        if (!configuredOptions.isEmpty()) {
            return configuredOptions;
        }

        List<String> coverageValues = templateCoverageValuesByLeadType().get(leadType);
        if (coverageValues == null) {
            coverageValues = new List<String>();
        }
        List<PicklistOption> options = new List<PicklistOption>();
        for (String coverageValue : coverageValues) {
            options.add(new PicklistOption(coverageValue, coverageValue));
        }
        return options;
    }

    @SuppressWarnings('PMD.ApexDoc')
    @AuraEnabled
    /**
     * @description Renders an ROI preview.
     * @param configJson ROI configuration JSON.
     * @param caseId DHS case identifier.
     * @return Rendered preview HTML.
     */
    public static String renderPreview(String configJson, Id caseId) {
        if (String.isBlank(configJson)) {
            configJson = defaultConfig(null, null);
        }

        Map<String, Object> config = (Map<String, Object>) JSON.deserializeUntyped(configJson);
        List<Object> elements = (List<Object>) config.get('elements');
        if (elements == null) {
            elements = new List<Object>();
        }

        Set<String> caseFields = new Set<String>{ 'Id', 'Name' };
        Set<String> leadFields = new Set<String>{ 'Id', 'Name', 'Item_number__c', 'LeadType__c' };

        collectFields(elements, caseFields, leadFields);

        DHS_Case__c caseRecord = null;
        List<DHS_Lead__c> leads = new List<DHS_Lead__c>();

        if (caseId != null) {
            String caseQuery = 'SELECT ' + sortedJoin(caseFields) + ' FROM DHS_Case__c WHERE Id = :caseId LIMIT 1';
            caseRecord = Database.query(String.escapeSingleQuotes(caseQuery), AccessLevel.USER_MODE);

            String leadQuery = 'SELECT ' + sortedJoin(leadFields) + ' FROM DHS_Lead__c WHERE DHS_Case__c = :caseId ORDER BY Item_number__c ASC NULLS LAST, CreatedDate ASC';
            leads = Database.query(String.escapeSingleQuotes(leadQuery), AccessLevel.USER_MODE);
        }

        Map<String, Object> caseMap = caseRecord == null ? new Map<String, Object>() : flattenRecord(caseRecord);
        return '<div class="roi-preview-document">' + renderConfigElements(elements, caseMap, leads, null) + '</div>';
    }

    /**
     * @description Renders a case preview.
     * @param caseId DHS case identifier.
     * @return Rendered case preview HTML.
     */
    @SuppressWarnings('PMD.ApexDoc')
    public static String renderCasePreview(Id caseId) {
        return renderCasePreview(caseId, null);
    }

    /**
     * @description Renders a case preview for a template sequence.
     * @param caseId DHS case identifier.
     * @param sequenceId Optional template sequence identifier.
     * @return Rendered case preview HTML.
     */
    @SuppressWarnings('PMD.ApexDoc')
    public static String renderCasePreview(Id caseId, Id sequenceId) {
        if (caseId == null) {
            return '<div class="roi-preview-document"><div class="roi-preview-page"><p>No case was selected.</p></div></div>';
        }

        List<DHS_Lead__c> templateSelectorLeads = [
            SELECT Id, Name, Item_number__c, LeadType__c, Coverage_Type__c, Attachment_Description__c
            FROM DHS_Lead__c
            WHERE DHS_Case__c = :caseId
            WITH USER_MODE ORDER BY Item_number__c ASC NULLS LAST, CreatedDate ASC
        ];
        Set<String> hideTitleItemNumbers = new Set<String>();
        if (sequenceId != null) {
            templateSelectorLeads = orderLeadsBySequence(caseId, sequenceId, templateSelectorLeads);
            hideTitleItemNumbers = hiddenTitleItemNumbers(caseId, sequenceId);
        }
        if (templateSelectorLeads.isEmpty()) {
            return '<div class="roi-preview-document"><div class="roi-preview-page"><p>No leads were found for this case.</p></div></div>';
        }

        Set<String> templateTitles = new Set<String>();
        for (String caseTemplateName : caseLevelTemplateNames()) {
            templateTitles.add(configTitleFor(caseTemplateName, caseTemplateName));
        }
        for (DHS_Lead__c leadRecord : templateSelectorLeads) {
            templateTitles.add(configTitleFor(leadRecord.LeadType__c, leadRecord.Coverage_Type__c));
        }

        Map<String, String> configByTitle = loadConfigsByTitle(templateTitles);
        Map<String, ParsedTemplate> templateByTitle = new Map<String, ParsedTemplate>();
        for (String title : configByTitle.keySet()) {
            templateByTitle.put(title, new ParsedTemplate(configByTitle.get(title)));
        }

        Map<Id, String> leadIdToTemplateTitle = new Map<Id, String>();
        Set<String> caseFields = new Set<String>{ 'Id', 'Name' };
        Set<String> leadFields = new Set<String>{ 'Id', 'Name', 'Item_number__c', 'LeadType__c', 'Coverage_Type__c' };

        for (String caseTemplateName : caseLevelTemplateNames()) {
            ParsedTemplate parsedTemplate = templateByTitle.get(configTitleFor(caseTemplateName, caseTemplateName));
            if (parsedTemplate != null) {
                collectFields(parsedTemplate.elements, caseFields, leadFields);
            }
        }

        for (DHS_Lead__c leadRecord : templateSelectorLeads) {
            String templateTitle = configTitleFor(leadRecord.LeadType__c, leadRecord.Coverage_Type__c);
            ParsedTemplate parsedTemplate = templateByTitle.get(templateTitle);
            if (parsedTemplate == null) {
                continue;
            }
            leadIdToTemplateTitle.put(leadRecord.Id, templateTitle);
            collectFields(parsedTemplate.elements, caseFields, leadFields);
        }

        if (leadIdToTemplateTitle.isEmpty()) {
            return '<div class="roi-preview-document"><div class="roi-preview-page"><p>No ROI designer templates matched the leads on this case.</p></div></div>';
        }

        String caseQuery = 'SELECT ' + sortedJoin(caseFields) + ' FROM DHS_Case__c WHERE Id = :caseId LIMIT 1';
        DHS_Case__c caseRecord = Database.query(String.escapeSingleQuotes(caseQuery), AccessLevel.USER_MODE);
        Map<String, Object> caseMap = flattenRecord(caseRecord);

        Set<Id> configuredLeadIds = leadIdToTemplateTitle.keySet();
        Map<Id, DHS_Lead__c> leadById = new Map<Id, DHS_Lead__c>((List<DHS_Lead__c>) Database.query(
            String.escapeSingleQuotes('SELECT ' + sortedJoin(leadFields) + ' FROM DHS_Lead__c WHERE Id IN :configuredLeadIds ORDER BY Item_number__c ASC NULLS LAST, CreatedDate ASC')
        , AccessLevel.USER_MODE));

        List<String> htmlParts = new List<String>{ '<div class="roi-preview-document">' };
        for (String caseTemplateName : caseLevelTemplateNames()) {
            if (leadContextTemplateNames().contains(caseTemplateName)) {
                continue;
            }
            ParsedTemplate caseTemplate = templateByTitle.get(configTitleFor(caseTemplateName, caseTemplateName));
            if (caseTemplate != null) {
                htmlParts.add(renderConfigElements(
                    caseTemplate.elements,
                    caseMap,
                    new List<DHS_Lead__c>(),
                    null,
                    caseTemplate.maxPage,
                    caseTemplate.pageHeights
                ));
            }
        }
        Map<String, ParsedTemplate> leadContextTemplates = new Map<String, ParsedTemplate>();
        for (String templateName : leadContextTemplateNames()) {
            ParsedTemplate parsedTemplate = templateByTitle.get(configTitleFor(templateName, templateName));
            if (parsedTemplate != null) {
                leadContextTemplates.put(templateName, parsedTemplate);
            }
        }
        Map<Id, Map<String, Object>> renderContextByLeadId = buildRenderContexts(templateSelectorLeads);
        for (DHS_Lead__c selectorLead : templateSelectorLeads) {
            if (!leadIdToTemplateTitle.containsKey(selectorLead.Id) || !leadById.containsKey(selectorLead.Id)) {
                continue;
            }
            DHS_Lead__c leadRecord = leadById.get(selectorLead.Id);
            Map<String, Object> renderContext = renderContextByLeadId.get(selectorLead.Id);
            ParsedTemplate parsedTemplate = templateByTitle.get(leadIdToTemplateTitle.get(selectorLead.Id));
            Boolean skipLeadTitle = hideTitleItemNumbers.contains(normalizeSequenceItemNumber(String.valueOf(selectorLead.Item_number__c)));
            htmlParts.add(renderConfigElementsWithContext(
                parsedTemplate.elements,
                caseMap,
                new List<DHS_Lead__c>{ leadRecord },
                leadRecord,
                parsedTemplate.maxPage,
                parsedTemplate.pageHeights,
                skipLeadTitle,
                renderContext,
                true
            ));
            Map<String, Object> leadMap = flattenRecord(leadRecord);
            for (String templateName : leadContextTemplateNames()) {
                ParsedTemplate leadContextTemplate = leadContextTemplates.get(templateName);
                if (leadContextTemplate == null || !hasRenderableElements(leadContextTemplate.elements, caseMap, leadMap, renderContext)) {
                    continue;
                }
                htmlParts.add(renderConfigElementsWithContext(
                    leadContextTemplate.elements,
                    caseMap,
                    new List<DHS_Lead__c>{ leadRecord },
                    leadRecord,
                    leadContextTemplate.maxPage,
                    leadContextTemplate.pageHeights,
                    false,
                    renderContext,
                    true
                ));
            }
        }
        htmlParts.add('</div>');
        return String.join(htmlParts, '');
    }

    private static Map<Id, Map<String, Object>> buildRenderContexts(List<DHS_Lead__c> leads) {
        Map<Id, Map<String, Object>> contextsByLeadId = new Map<Id, Map<String, Object>>();
        Integer subjectContactCount = 0;
        Integer subjectInterviewCount = 0;
        Integer residenceCount = 0;
        Boolean hasPAEI = false;
        Decimal paeiItemNumber;
        List<Decimal> subjectInterviewItemNumbers = new List<Decimal>();
        Map<String, Integer> leadCountsByContextKey = new Map<String, Integer>();
        for (String contextKey : summaryCountContextKeys()) {
            leadCountsByContextKey.put(contextKey, 0);
        }

        for (DHS_Lead__c leadRecord : leads) {
            leadCountsByContextKey.put('TotalReferencesCount', leadCountsByContextKey.get('TotalReferencesCount') + 1);
            if (String.isNotBlank(leadRecord.Attachment_Description__c)) {
                leadCountsByContextKey.put('AttachmentCount', leadCountsByContextKey.get('AttachmentCount') + 1);
            }
            String countContextKey = summaryCountContextKeyForLeadType(leadRecord.LeadType__c);
            if (String.isNotBlank(countContextKey)) {
                leadCountsByContextKey.put(countContextKey, leadCountsByContextKey.get(countContextKey) + 1);
            }
            if (isSubjectContactLead(leadRecord)) {
                subjectContactCount++;
            }
            if (isSubjectInterviewLead(leadRecord)) {
                subjectInterviewCount++;
                Decimal itemNumber = decimalItemNumber(leadRecord);
                if (itemNumber != null) {
                    subjectInterviewItemNumbers.add(itemNumber);
                }
            }
            if (isResidenceLead(leadRecord)) {
                residenceCount++;
            }
            if (isPAEILead(leadRecord)) {
                hasPAEI = true;
                paeiItemNumber = decimalItemNumber(leadRecord);
            }
        }

        Decimal closestSubjectInterviewToPAEI = closestItemNumber(paeiItemNumber, subjectInterviewItemNumbers);
        Integer subjectContactIndex = -1;
        Integer subjectInterviewIndex = -1;
        Integer residenceIndex = -1;
        for (DHS_Lead__c leadRecord : leads) {
            Boolean isSubjectContact = isSubjectContactLead(leadRecord);
            Boolean isSubjectInterview = isSubjectInterviewLead(leadRecord);
            Boolean isResidence = isResidenceLead(leadRecord);
            if (isSubjectContact) {
                subjectContactIndex++;
            }
            if (isSubjectInterview) {
                subjectInterviewIndex++;
            }
            if (isResidence) {
                residenceIndex++;
            }

            Map<String, Object> context = new Map<String, Object>();
            putContext(context, 'HasSubjectInterview', subjectInterviewCount > 0);
            putContext(context, 'HasSubjectRecontact', subjectContactCount > 0);
            putContext(context, 'HasResidence', residenceCount > 0);
            putContext(context, 'HasPAEI', hasPAEI);
            putContext(context, 'CurrentLeadType', leadRecord.LeadType__c);
            putContext(context, 'CurrentCoverageType', leadRecord.Coverage_Type__c);
            putContext(context, 'CurrentItemNumber', leadRecord.Item_number__c);
            for (String contextKey : leadCountsByContextKey.keySet()) {
                putContext(context, contextKey, leadCountsByContextKey.get(contextKey));
            }
            putContext(context, 'SubjectContactCount', subjectContactCount);
            putContext(context, 'SubjectInterviewCount', subjectInterviewCount);
            putContext(context, 'ResidenceCount', residenceCount);
            putContext(context, 'SubjectContactIndex', isSubjectContact ? subjectContactIndex : -1);
            putContext(context, 'SubjectInterviewIndex', isSubjectInterview ? subjectInterviewIndex : -1);
            putContext(context, 'ResidenceIndex', isResidence ? residenceIndex : -1);
            putContext(context, 'IsLastSubjectContact', isSubjectContact && subjectContactIndex == subjectContactCount - 1);
            putContext(context, 'IsFirstSubjectInterview', isSubjectInterview && subjectInterviewIndex == 0);
            putContext(context, 'IsFirstResidence', isResidence && residenceIndex == 0);
            putContext(context, 'IsClosestSubjectInterviewToPAEI', isSubjectInterview && closestSubjectInterviewToPAEI != null && decimalItemNumber(leadRecord) == closestSubjectInterviewToPAEI);
            putContext(context, 'RenderDisclaimerAfterSubjectRecontact', isSubjectContact && subjectContactIndex == subjectContactCount - 1 && subjectContactCount > 0);
            putContext(context, 'RenderDisclaimerAfterSubjectInterview', isSubjectInterview && subjectInterviewIndex == 0 && subjectInterviewCount > 0 && subjectContactCount == 0);
            putContext(context, 'RenderDisclaimerBeforeResidence', isResidence && residenceIndex == 0 && residenceCount > 0 && subjectInterviewCount == 0 && subjectContactCount == 0);
            putContext(context, 'ShouldRenderDisclaimer',
                (isSubjectContact && subjectContactIndex == subjectContactCount - 1 && subjectContactCount > 0)
                || (isSubjectInterview && subjectInterviewIndex == 0 && subjectInterviewCount > 0 && subjectContactCount == 0)
                || (isResidence && residenceIndex == 0 && residenceCount > 0 && subjectInterviewCount == 0 && subjectContactCount == 0)
            );
            contextsByLeadId.put(leadRecord.Id, context);
        }
        return contextsByLeadId;
    }

    private static List<String> summaryCountContextKeys() {
        return new List<String>{
            'EducationCount',
            'EmploymentCount',
            'FinancialCount',
            'FormerSpouseCount',
            'GeneralCount',
            'LawEnforcementCount',
            'MedicalCount',
            'PublicRecordsCount',
            'PAEICount',
            'ReferencesCount',
            'ResidenceCount',
            'SubjectInterviewCount',
            'SubjectContactCount',
            'UnemploymentCount',
            'AttachmentCount',
            'TotalReferencesCount'
        };
    }

    private static String summaryCountContextKeyForLeadType(String leadType) {
        if (String.isBlank(leadType)) {
            return null;
        }
        String normalized = leadType.toLowerCase();
        Map<String, String> contextKeyByToken = summaryCountContextKeyByLeadTypeToken();
        for (String token : summaryCountLeadTypeTokens()) {
            if (normalized.contains(token)) {
                return contextKeyByToken.get(token);
            }
        }
        return null;
    }

    private static List<String> summaryCountLeadTypeTokens() {
        return new List<String>{
            'education',
            'employment',
            'financial',
            'former spouse',
            'general',
            'law enforcement',
            'medical',
            'public records',
            'publicly available electronic information',
            'paei',
            'references',
            'residence',
            'subject interview',
            'subject recontact',
            'subject contact',
            'unemployment'
        };
    }

    private static Map<String, String> summaryCountContextKeyByLeadTypeToken() {
        return new Map<String, String>{
            'education' => 'EducationCount',
            'employment' => 'EmploymentCount',
            'financial' => 'FinancialCount',
            'former spouse' => 'FormerSpouseCount',
            'general' => 'GeneralCount',
            'law enforcement' => 'LawEnforcementCount',
            'medical' => 'MedicalCount',
            'public records' => 'PublicRecordsCount',
            'publicly available electronic information' => 'PAEICount',
            'paei' => 'PAEICount',
            'references' => 'ReferencesCount',
            'residence' => 'ResidenceCount',
            'subject interview' => 'SubjectInterviewCount',
            'subject recontact' => 'SubjectContactCount',
            'subject contact' => 'SubjectContactCount',
            'unemployment' => 'UnemploymentCount'
        };
    }

    private static void putContext(Map<String, Object> context, String key, Object value) {
        context.put(key, value);
        context.put(key.toLowerCase(), value);
    }

    private static Boolean isSubjectContactLead(DHS_Lead__c leadRecord) {
        String leadType = String.valueOf(leadRecord.LeadType__c).toLowerCase();
        return leadType.contains('subject recontact');
    }

    private static Boolean isSubjectInterviewLead(DHS_Lead__c leadRecord) {
        String leadType = String.valueOf(leadRecord.LeadType__c).toLowerCase();
        return leadType.contains('subject interview');
    }

    private static Boolean isResidenceLead(DHS_Lead__c leadRecord) {
        String leadType = String.valueOf(leadRecord.LeadType__c).toLowerCase();
        return leadType.contains('residence');
    }

    private static Boolean isPAEILead(DHS_Lead__c leadRecord) {
        String leadType = String.valueOf(leadRecord.LeadType__c).toLowerCase();
        return leadType.contains('publicly available electronic information') || leadType.contains('paei');
    }

    private static Decimal decimalItemNumber(DHS_Lead__c leadRecord) {
        try {
            return leadRecord == null || leadRecord.Item_number__c == null ? null : Decimal.valueOf(String.valueOf(leadRecord.Item_number__c));
        } catch (Exception ex) {
            return null;
        }
    }

    private static Decimal closestItemNumber(Decimal target, List<Decimal> candidates) {
        if (target == null || candidates == null || candidates.isEmpty()) {
            return null;
        }
        Decimal closest;
        Decimal smallestDistance;
        for (Decimal candidate : candidates) {
            Decimal distance = (candidate - target).abs();
            if (smallestDistance == null || distance < smallestDistance) {
                closest = candidate;
                smallestDistance = distance;
            }
        }
        return closest;
    }

    private static Set<String> hiddenTitleItemNumbers(Id caseId, Id sequenceId) {
        Set<String> itemNumbers = new Set<String>();
        List<DHS_ROI_Report_Order__c> orders = [
            SELECT HideTitles__c
            FROM DHS_ROI_Report_Order__c
            WHERE Id = :sequenceId
            AND DHS_Case__c = :caseId
            WITH USER_MODE LIMIT 1
        ];
        if (orders.isEmpty() || String.isBlank(orders[0].HideTitles__c)) {
            return itemNumbers;
        }
        for (String rawItemNumber : orders[0].HideTitles__c.split(',')) {
            String normalizedItemNumber = normalizeSequenceItemNumber(rawItemNumber);
            if (String.isNotBlank(normalizedItemNumber)) {
                itemNumbers.add(normalizedItemNumber);
            }
        }
        return itemNumbers;
    }

    private static List<DHS_Lead__c> orderLeadsBySequence(Id caseId, Id sequenceId, List<DHS_Lead__c> fallbackLeads) {
        List<DHS_ROI_Report_Order__c> orders = [
            SELECT ROI_Report_Order__c
            FROM DHS_ROI_Report_Order__c
            WHERE Id = :sequenceId
            AND DHS_Case__c = :caseId
            WITH USER_MODE LIMIT 1
        ];
        if (orders.isEmpty() || String.isBlank(orders[0].ROI_Report_Order__c)) {
            return fallbackLeads;
        }

        List<String> orderedItemNumbers = new List<String>();
        for (String rawItemNumber : orders[0].ROI_Report_Order__c.split(',')) {
            String normalizedItemNumber = normalizeSequenceItemNumber(rawItemNumber);
            if (String.isNotBlank(normalizedItemNumber)) {
                orderedItemNumbers.add(normalizedItemNumber);
            }
        }
        if (orderedItemNumbers.isEmpty()) {
            return fallbackLeads;
        }

        Map<String, DHS_Lead__c> leadByItemNumber = new Map<String, DHS_Lead__c>();
        for (DHS_Lead__c leadRecord : fallbackLeads) {
            leadByItemNumber.put(normalizeSequenceItemNumber(String.valueOf(leadRecord.Item_number__c)), leadRecord);
        }

        List<DHS_Lead__c> orderedLeads = new List<DHS_Lead__c>();
        Set<Id> usedLeadIds = new Set<Id>();
        for (String itemNumber : orderedItemNumbers) {
            DHS_Lead__c matchingLead = leadByItemNumber.get(itemNumber);
            if (matchingLead != null && !usedLeadIds.contains(matchingLead.Id)) {
                orderedLeads.add(matchingLead);
                usedLeadIds.add(matchingLead.Id);
            }
        }
        return orderedLeads;
    }

    private static String normalizeSequenceItemNumber(String itemNumber) {
        if (String.isBlank(itemNumber)) {
            return '';
        }
        String normalized = itemNumber.trim();
        if (normalized.endsWith('.0')) {
            normalized = normalized.substring(0, normalized.length() - 2);
        }
        return normalized;
    }

    private static Map<String, String> loadConfigsByTitle(Set<String> configTitles) {
        Map<String, String> configsByTitle = new Map<String, String>();
        if (configTitles == null || configTitles.isEmpty()) {
            return configsByTitle;
        }

        Account isnAccount = getIsnAccount();
        Map<String, Id> titleToDocumentId = new Map<String, Id>();
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :isnAccount.Id
            AND ContentDocument.Title IN :configTitles
            WITH USER_MODE ORDER BY ContentDocument.CreatedDate DESC
        ]) {
            if (!titleToDocumentId.containsKey(link.ContentDocument.Title)) {
                titleToDocumentId.put(link.ContentDocument.Title, link.ContentDocumentId);
            }
        }

        if (titleToDocumentId.isEmpty()) {
            return configsByTitle;
        }

        Map<Id, String> documentIdToTitle = new Map<Id, String>();
        for (String title : titleToDocumentId.keySet()) {
            documentIdToTitle.put(titleToDocumentId.get(title), title);
        }

        for (ContentVersion version : [
            SELECT ContentDocumentId, VersionData
            FROM ContentVersion
            WHERE ContentDocumentId IN :documentIdToTitle.keySet()
            AND IsLatest = true WITH USER_MODE
        ]) {
            String title = documentIdToTitle.get(version.ContentDocumentId);
            if (String.isNotBlank(title) && !configsByTitle.containsKey(title)) {
                configsByTitle.put(title, version.VersionData.toString());
            }
        }

        return configsByTitle;
    }

    private static String renderConfigElements(List<Object> elements, Map<String, Object> caseMap, List<DHS_Lead__c> leads, DHS_Lead__c selectedLead) {
        Integer maxPage = maxPage(elements);
        return renderConfigElements(elements, caseMap, leads, selectedLead, maxPage, pageHeights(elements, maxPage));
    }

    private static String renderConfigElements(List<Object> elements, Map<String, Object> caseMap, List<DHS_Lead__c> leads, DHS_Lead__c selectedLead, Integer maxPage, Map<Integer, Integer> pageHeights) {
        return renderConfigElements(elements, caseMap, leads, selectedLead, maxPage, pageHeights, false);
    }

    private static String renderConfigElements(List<Object> elements, Map<String, Object> caseMap, List<DHS_Lead__c> leads, DHS_Lead__c selectedLead, Integer maxPage, Map<Integer, Integer> pageHeights, Boolean skipLeadTitle) {
        return renderConfigElements(elements, caseMap, leads, selectedLead, maxPage, pageHeights, skipLeadTitle, false);
    }

    private static String renderConfigElements(List<Object> elements, Map<String, Object> caseMap, List<DHS_Lead__c> leads, DHS_Lead__c selectedLead, Integer maxPage, Map<Integer, Integer> pageHeights, Boolean skipLeadTitle, Boolean compactPages) {
        List<String> htmlParts = new List<String>();
        Map<String, Object> selectedLeadMap = selectedLead == null ? null : flattenRecord(selectedLead);
        List<Map<String, Object>> leadMaps = new List<Map<String, Object>>();
        if (selectedLeadMap == null) {
            for (DHS_Lead__c lead : leads) {
                leadMaps.add(flattenRecord(lead));
            }
        }
        for (Integer pageNumber = 1; pageNumber <= maxPage; pageNumber++) {
            Integer contentHeight = pageHeights.containsKey(pageNumber) ? pageHeights.get(pageNumber) : 96;
            List<RenderCandidate> pageElements = new List<RenderCandidate>();
            for (Object rawElement : elements) {
                Map<String, Object> element = (Map<String, Object>) rawElement;
                Integer elementPage = 1;
                try {
                    elementPage = Integer.valueOf(getString(element, 'page', '1'));
                } catch (Exception ex) {
                    elementPage = 1;
                }
                if (elementPage == pageNumber) {
                    if (skipLeadTitle == true && isLeadTitleElement(element)) {
                        continue;
                    }
                    pageElements.add(new RenderCandidate(element));
                }
            }
            pageElements.sort();

            Integer topTrim = compactPages == true ? compactPageTopTrim(pageElements, caseMap, leadMaps, selectedLeadMap) : 0;
            Integer yShift = 0;
            Integer renderedBottom = 0;
            List<String> pageHtml = new List<String>();
            for (RenderCandidate candidate : pageElements) {
                if (!shouldRenderElement(candidate.element, caseMap, leadMaps, selectedLeadMap)) {
                    yShift += candidate.height;
                    continue;
                }
                Map<String, Object> adjustedElement = new Map<String, Object>(candidate.element);
                Integer adjustedY = Math.max(0, candidate.y - yShift - topTrim);
                adjustedElement.put('y', adjustedY);
                Integer renderedHeight = renderedElementHeight(adjustedElement, caseMap, leadMaps, selectedLeadMap, candidate.height);
                adjustedElement.put('height', renderedHeight);
                pageHtml.add(selectedLeadMap == null ? renderElement(adjustedElement, caseMap, leadMaps) : renderElementForSelectedLead(adjustedElement, caseMap, selectedLeadMap));
                renderedBottom = Math.max(renderedBottom, adjustedY + renderedHeight);
                yShift += candidate.height - renderedHeight;
            }

            Integer pageHeight = compactPages == true
                ? Math.max(24, renderedBottom + 10)
                : Math.max(96, contentHeight - yShift);
            htmlParts.add('<div class="roi-preview-page" style="min-height:' + pageHeight + 'px;">');
            htmlParts.addAll(pageHtml);
            htmlParts.add('</div>');
        }
        return String.join(htmlParts, '');
    }

    private static Integer compactPageTopTrim(List<RenderCandidate> pageElements, Map<String, Object> caseMap, List<Map<String, Object>> leadMaps, Map<String, Object> selectedLeadMap) {
        Integer firstY;
        for (RenderCandidate candidate : pageElements) {
            if (!shouldRenderElement(candidate.element, caseMap, leadMaps, selectedLeadMap)) {
                continue;
            }
            firstY = firstY == null ? candidate.y : Math.min(firstY, candidate.y);
        }
        if (firstY == null) {
            return 0;
        }
        return Math.max(0, firstY - 8);
    }

    private static String renderConfigElementsWithContext(
        List<Object> elements,
        Map<String, Object> caseMap,
        List<DHS_Lead__c> leads,
        DHS_Lead__c selectedLead,
        Integer maxPage,
        Map<Integer, Integer> pageHeights,
        Boolean skipLeadTitle,
        Map<String, Object> renderContext
    ) {
        return renderConfigElementsWithContext(elements, caseMap, leads, selectedLead, maxPage, pageHeights, skipLeadTitle, renderContext, false);
    }

    private static String renderConfigElementsWithContext(
        List<Object> elements,
        Map<String, Object> caseMap,
        List<DHS_Lead__c> leads,
        DHS_Lead__c selectedLead,
        Integer maxPage,
        Map<Integer, Integer> pageHeights,
        Boolean skipLeadTitle,
        Map<String, Object> renderContext,
        Boolean compactPages
    ) {
        Map<String, Object> previousContext = activeRenderContext;
        activeRenderContext = renderContext == null ? new Map<String, Object>() : renderContext;
        try {
            return renderConfigElements(elements, caseMap, leads, selectedLead, maxPage, pageHeights, skipLeadTitle, compactPages);
        } finally {
            activeRenderContext = previousContext;
        }
    }

    private static Boolean hasRenderableElements(List<Object> elements, Map<String, Object> caseMap, Map<String, Object> leadMap, Map<String, Object> renderContext) {
        Map<String, Object> previousContext = activeRenderContext;
        activeRenderContext = renderContext == null ? new Map<String, Object>() : renderContext;
        try {
            for (Object rawElement : elements) {
                Map<String, Object> element = (Map<String, Object>) rawElement;
                if (shouldRenderElement(element, caseMap, new List<Map<String, Object>>{ leadMap }, leadMap)) {
                    return true;
                }
            }
            return false;
        } finally {
            activeRenderContext = previousContext;
        }
    }

    private static Boolean isLeadTitleElement(Map<String, Object> element) {
        if (element == null || getString(element, 'scope', '') != 'lead') {
            return false;
        }
        String idValue = getString(element, 'id', '').toLowerCase();
        String labelValue = getString(element, 'label', '').toLowerCase();
        String typeValue = getString(element, 'type', '').toLowerCase();
        return idValue.endsWith('title')
            || idValue.contains('lead-title')
            || idValue.contains('interview-title')
            || labelValue == 'title'
            || (typeValue == 'section' && labelValue.contains('title'));
    }

    private static Integer renderedElementHeight(Map<String, Object> element, Map<String, Object> caseMap, List<Map<String, Object>> leadMaps, Map<String, Object> selectedLeadMap, Integer configuredHeight) {
        String type = getString(element, 'type', '').toLowerCase();
        if (type != 'table') {
            if (type == 'text' || type == 'section' || type == 'group') {
                return renderedTextHeight(element, caseMap, selectedLeadMap, configuredHeight);
            }
            return configuredHeight;
        }

        Integer rowCount = 0;
        if (selectedLeadMap != null) {
            rowCount = visibleTableRowCount(element, caseMap, selectedLeadMap);
        } else {
            for (Map<String, Object> leadMap : leadMaps) {
                if (matchesLeadType(element, leadMap) && conditionsPass(element, caseMap, leadMap)) {
                    rowCount += visibleTableRowCount(element, caseMap, leadMap);
                }
            }
            if (rowCount == 0 && getString(element, 'scope', 'case') != 'lead') {
                rowCount = visibleTableRowCount(element, caseMap, null);
            }
        }

        if (rowCount == 0) {
            return 0;
        }

        Integer fontSize = Math.max(8, Math.min(48, getInteger(element, 'fontSize', 13)));
        Integer padding = Math.max(0, Math.min(40, getInteger(element, 'tableCellPadding', 4)));
        Integer rowHeight = Math.max(18, fontSize + (padding * 2) + 6);
        Integer borderAllowance = tableBorder(element) == '0' ? 0 : 2;
        return Math.max(rowHeight, (rowHeight * rowCount) + borderAllowance);
    }

    private static Integer renderedTextHeight(Map<String, Object> element, Map<String, Object> caseMap, Map<String, Object> leadMap, Integer configuredHeight) {
        String resolvedText = sanitizeRichText(resolveTemplate(element, caseMap, leadMap, ''));
        if (String.isBlank(resolvedText)) {
            return 0;
        }

        Integer fontSize = Math.max(8, Math.min(72, getInteger(element, 'fontSize', 13)));
        Integer padding = Math.max(0, Math.min(40, getInteger(element, 'padding', 6)));
        Integer width = Math.max(80, getInteger(element, 'width', 360) - (padding * 2));
        Integer lineHeight = Math.max(14, fontSize + 6);
        Integer lineCount = estimatedLineCount(resolvedText, width, fontSize);
        Integer borderAllowance = blockBorder(element) == '0' ? 0 : 2;
        Integer estimatedHeight = (lineCount * lineHeight) + (padding * 2) + borderAllowance + 4;
        return Math.max(lineHeight + (padding * 2), estimatedHeight);
    }

    private static Integer estimatedLineCount(String html, Integer width, Integer fontSize) {
        String normalized = html
            .replaceAll('(?i)</tr\\s*>', '\n')
            .replaceAll('(?i)<br\\s*/?>', '\n')
            .replaceAll('(?i)</p\\s*>', '\n')
            .replaceAll('(?i)</div\\s*>', '\n')
            .replaceAll('(?i)</li\\s*>', '\n');
        normalized = normalized.replaceAll('(?is)<[^>]+>', '');
        normalized = normalized.replace('&nbsp;', ' ');
        List<String> parts = normalized.split('\\n');
        Integer lineCount = 0;
        Integer approximateCharsPerLine = Math.max(12, width / Math.max(6, Math.max(1, fontSize / 2)));
        for (String part : parts) {
            String line = part == null ? '' : part.trim();
            if (String.isBlank(line)) {
                lineCount++;
                continue;
            }
            lineCount += Math.max(1, (Integer) Math.ceil(Decimal.valueOf(line.length()) / Decimal.valueOf(approximateCharsPerLine)));
        }
        return Math.max(1, lineCount);
    }

    private static Integer visibleTableRowCount(Map<String, Object> element, Map<String, Object> caseMap, Map<String, Object> leadMap) {
        List<Object> rowsConfig = (List<Object>) element.get('tableRows');
        if (rowsConfig == null || rowsConfig.isEmpty()) {
            List<Object> fields = (List<Object>) element.get('fields');
            rowsConfig = new List<Object>();
            if (fields != null) {
                for (Object fieldObj : fields) {
                    rowsConfig.add(new Map<String, Object>{ 'fieldPath' => String.valueOf(fieldObj) });
                }
            }
        }

        Integer count = 0;
        for (Object rowObj : rowsConfig) {
            Map<String, Object> rowConfig = (Map<String, Object>) rowObj;
            if (conditionsPass(rowConfig, caseMap, leadMap)) {
                count++;
            }
        }
        return count;
    }

    private static Integer maxPage(List<Object> elements) {
        Integer result = 1;
        for (Object rawElement : elements) {
            Map<String, Object> element = (Map<String, Object>) rawElement;
            try {
                result = Math.max(result, Integer.valueOf(getString(element, 'page', '1')));
            } catch (Exception ex) {
                result = Math.max(result, 1);
            }
        }
        return result;
    }

    private static Map<Integer, Integer> pageHeights(List<Object> elements, Integer maxPage) {
        Map<Integer, Integer> heights = new Map<Integer, Integer>();
        for (Integer pageNumber = 1; pageNumber <= maxPage; pageNumber++) {
            heights.put(pageNumber, 96);
        }
        for (Object rawElement : elements) {
            Map<String, Object> element = (Map<String, Object>) rawElement;
            Integer elementPage = 1;
            try {
                elementPage = Integer.valueOf(getString(element, 'page', '1'));
            } catch (Exception ex) {
                elementPage = 1;
            }
            Integer y = getInteger(element, 'y', 72);
            Integer height = getInteger(element, 'height', 60);
            heights.put(elementPage, Math.max(heights.containsKey(elementPage) ? heights.get(elementPage) : 96, y + height + 24));
        }
        return heights;
    }

    private static Account getIsnAccount() {
        List<Account> accounts = [
            SELECT Id, Name
            FROM Account
            WHERE Name = 'ISN'
            WITH USER_MODE ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        if (accounts.isEmpty()) {
            throw new AuraHandledException('Could not find Account named ISN to store ROI builder config.');
        }
        return accounts[0];
    }

    private static List<FieldOption> getFieldOptions(String objectName, String labelPrefix, String scope, String tokenPrefix) {
        List<FieldOption> options = new List<FieldOption>();
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null) {
            return options;
        }

        Map<String, Schema.SObjectField> fields = getFieldMap(objectName);
        List<String> names = new List<String>(fields.keySet());
        names.sort();
        for (String fieldName : names) {
            Schema.DescribeFieldResult describeField = fields.get(fieldName).getDescribe();
            if (!describeField.isAccessible()) {
                continue;
            }
            options.add(new FieldOption(labelPrefix + ': ' + describeField.getLabel(), tokenPrefix + '.' + fieldName, scope));
        }
        return options;
    }

    private static List<FieldOption> getContextFieldOptions() {
        return new List<FieldOption>{
            new FieldOption('Has Subject Interview', 'Context.HasSubjectInterview', 'context'),
            new FieldOption('Has Subject Recontact', 'Context.HasSubjectRecontact', 'context'),
            new FieldOption('Has Residence', 'Context.HasResidence', 'context'),
            new FieldOption('Has PAEI', 'Context.HasPAEI', 'context'),
            new FieldOption('Current Lead Type', 'Context.CurrentLeadType', 'context'),
            new FieldOption('Current Coverage Type', 'Context.CurrentCoverageType', 'context'),
            new FieldOption('Current Item Number', 'Context.CurrentItemNumber', 'context'),
            new FieldOption('Subject Contact Count', 'Context.SubjectContactCount', 'context'),
            new FieldOption('Subject Interview Count', 'Context.SubjectInterviewCount', 'context'),
            new FieldOption('Residence Count', 'Context.ResidenceCount', 'context'),
            new FieldOption('Education Count', 'Context.EducationCount', 'context'),
            new FieldOption('Employment Count', 'Context.EmploymentCount', 'context'),
            new FieldOption('Financial Count', 'Context.FinancialCount', 'context'),
            new FieldOption('Former Spouse Count', 'Context.FormerSpouseCount', 'context'),
            new FieldOption('General Count', 'Context.GeneralCount', 'context'),
            new FieldOption('Law Enforcement Count', 'Context.LawEnforcementCount', 'context'),
            new FieldOption('Medical Count', 'Context.MedicalCount', 'context'),
            new FieldOption('Public Records Count', 'Context.PublicRecordsCount', 'context'),
            new FieldOption('PAEI Count', 'Context.PAEICount', 'context'),
            new FieldOption('References Count', 'Context.ReferencesCount', 'context'),
            new FieldOption('Unemployment Count', 'Context.UnemploymentCount', 'context'),
            new FieldOption('Attachment Count', 'Context.AttachmentCount', 'context'),
            new FieldOption('Total References Count', 'Context.TotalReferencesCount', 'context'),
            new FieldOption('Subject Contact Index', 'Context.SubjectContactIndex', 'context'),
            new FieldOption('Subject Interview Index', 'Context.SubjectInterviewIndex', 'context'),
            new FieldOption('Residence Index', 'Context.ResidenceIndex', 'context'),
            new FieldOption('Is Last Subject Contact', 'Context.IsLastSubjectContact', 'context'),
            new FieldOption('Is First Subject Interview', 'Context.IsFirstSubjectInterview', 'context'),
            new FieldOption('Is First Residence', 'Context.IsFirstResidence', 'context'),
            new FieldOption('Is Closest Subject Interview To PAEI', 'Context.IsClosestSubjectInterviewToPAEI', 'context'),
            new FieldOption('Render Disclaimer After Subject Recontact', 'Context.RenderDisclaimerAfterSubjectRecontact', 'context'),
            new FieldOption('Render Disclaimer After Subject Interview', 'Context.RenderDisclaimerAfterSubjectInterview', 'context'),
            new FieldOption('Render Disclaimer Before Residence', 'Context.RenderDisclaimerBeforeResidence', 'context'),
            new FieldOption('Should Render Disclaimer', 'Context.ShouldRenderDisclaimer', 'context')
        };
    }

    private static void collectFields(List<Object> elements, Set<String> caseFields, Set<String> leadFields) {
        for (Object rawElement : elements) {
            Map<String, Object> element = (Map<String, Object>) rawElement;
            addField(String.valueOf(element.get('fieldPath')), caseFields, leadFields);
            collectTemplateFields(String.valueOf(element.get('text')), caseFields, leadFields);
            collectTokenFields((List<Object>) element.get('tokens'), caseFields, leadFields);

            List<Object> fields = (List<Object>) element.get('fields');
            if (fields != null) {
                for (Object fieldObj : fields) {
                    addField(String.valueOf(fieldObj), caseFields, leadFields);
                }
            }

            List<Object> tableRows = (List<Object>) element.get('tableRows');
            if (tableRows != null) {
                for (Object rowObj : tableRows) {
                    Map<String, Object> row = (Map<String, Object>) rowObj;
                    addField(String.valueOf(row.get('fieldPath')), caseFields, leadFields);
                    List<Object> rowConditions = (List<Object>) row.get('conditions');
                    if (rowConditions != null) {
                        for (Object conditionObj : rowConditions) {
                            Map<String, Object> condition = (Map<String, Object>) conditionObj;
                            addField(String.valueOf(condition.get('fieldPath')), caseFields, leadFields);
                        }
                    }
                }
            }

            List<Object> conditions = (List<Object>) element.get('conditions');
            if (conditions != null) {
                for (Object conditionObj : conditions) {
                    Map<String, Object> condition = (Map<String, Object>) conditionObj;
                    addField(String.valueOf(condition.get('fieldPath')), caseFields, leadFields);
                }
            }
        }
    }

    private static void collectTemplateFields(String template, Set<String> caseFields, Set<String> leadFields) {
        if (String.isBlank(template)) {
            return;
        }
        Pattern tokenPattern = Pattern.compile('\\{([A-Za-z0-9_\\.]+)\\}');
        Matcher matcher = tokenPattern.matcher(template);
        while (matcher.find()) {
            addField(matcher.group(1), caseFields, leadFields);
        }
    }

    private static void collectTokenFields(List<Object> tokens, Set<String> caseFields, Set<String> leadFields) {
        if (tokens == null) {
            return;
        }
        for (Object tokenObj : tokens) {
            Map<String, Object> token = (Map<String, Object>) tokenObj;
            addField(String.valueOf(token.get('fieldPath')), caseFields, leadFields);
        }
    }

    private static void addField(String fieldPath, Set<String> caseFields, Set<String> leadFields) {
        if (String.isBlank(fieldPath) || fieldPath == 'null') {
            return;
        }
        String cleanPath = fieldPath.trim();
        if (!Pattern.compile('[A-Za-z0-9_\\.]+').matcher(cleanPath).matches()) {
            return;
        }
        addScopedField(cleanPath, caseFields, leadFields);
    }

    private static void addScopedField(String cleanPath, Set<String> caseFields, Set<String> leadFields) {
        if (cleanPath.startsWith('DHS_Lead__c.')) {
            String canonicalLeadField = canonicalFieldName('DHS_Lead__c', cleanPath.substringAfter('.'));
            if (String.isNotBlank(canonicalLeadField)) {
                addUniqueQueryField(leadFields, canonicalLeadField);
            }
        } else if (cleanPath.startsWith('DHS_Case__c.')) {
            String canonicalCaseField = canonicalFieldName('DHS_Case__c', cleanPath.substringAfter('.'));
            if (String.isNotBlank(canonicalCaseField)) {
                addUniqueQueryField(caseFields, canonicalCaseField);
            }
        } else if (cleanPath.startsWith('DHS_Contact__r.')) {
            String canonicalContactField = canonicalFieldName('DHS_Contact__c', cleanPath.substringAfter('.'));
            if (String.isNotBlank(canonicalContactField)) {
                addUniqueQueryField(caseFields, 'DHS_Contact__r.' + canonicalContactField);
            }
        }
    }

    private static Boolean isValidField(String objectName, String fieldName) {
        return String.isNotBlank(canonicalFieldName(objectName, fieldName));
    }

    private static String canonicalFieldName(String objectName, String fieldName) {
        if (String.isBlank(objectName) || String.isBlank(fieldName) || fieldName.contains('.')) {
            return null;
        }
        Map<String, Schema.SObjectField> fieldMap = getFieldMap(objectName);
        if (fieldMap.containsKey(fieldName) && fieldMap.get(fieldName).getDescribe().isAccessible()) {
            return fieldName;
        }
        String apiName = getFieldApiByLower(objectName).get(fieldName.toLowerCase());
        if (String.isNotBlank(apiName) && fieldMap.get(apiName).getDescribe().isAccessible()) {
            return apiName;
        }
        return null;
    }

    private static void addUniqueQueryField(Set<String> fields, String fieldName) {
        if (String.isBlank(fieldName)) {
            return;
        }
        String lowerFieldName = fieldName.toLowerCase();
        for (String existingField : fields) {
            if (existingField.toLowerCase() == lowerFieldName) {
                return;
            }
        }
        fields.add(fieldName);
    }

    private static List<PicklistOption> getActivePicklistOptions(String objectName, String fieldName) {
        List<PicklistOption> options = new List<PicklistOption>();
        if (String.isBlank(objectName) || String.isBlank(fieldName)) {
            return options;
        }

        Map<String, Schema.SObjectField> fieldMap = getFieldMap(objectName);
        if (!fieldMap.containsKey(fieldName)) {
            return options;
        }

        Schema.DescribeFieldResult describeField = fieldMap.get(fieldName).getDescribe();
        if (!describeField.isAccessible()) {
            return options;
        }

        for (Schema.PicklistEntry entry : describeField.getPicklistValues()) {
            if (entry.isActive()) {
                options.add(new PicklistOption(entry.getLabel(), entry.getValue()));
            }
        }
        return options;
    }

    private static Schema.DescribeFieldResult describeFieldPath(String fieldPath) {
        if (String.isBlank(fieldPath)) {
            return null;
        }
        String cacheKey = fieldPath.trim().toLowerCase();
        if (describeByFieldPath.containsKey(cacheKey)) {
            return describeByFieldPath.get(cacheKey);
        }

        FieldReference fieldReference = parseFieldReference(fieldPath);
        if (fieldReference == null || fieldReference.fieldName.contains('.')) {
            return null;
        }

        String canonicalField = canonicalFieldName(fieldReference.objectName, fieldReference.fieldName);
        if (String.isBlank(canonicalField)) {
            return null;
        }
        Schema.DescribeFieldResult describeField = getFieldMap(fieldReference.objectName).get(canonicalField).getDescribe();
        describeByFieldPath.put(cacheKey, describeField);
        return describeField;
    }

    private static FieldReference parseFieldReference(String fieldPath) {
        if (fieldPath.startsWith('DHS_Lead__c.')) {
            return new FieldReference('DHS_Lead__c', fieldPath.substringAfter('.'));
        }
        if (fieldPath.startsWith('DHS_Case__c.')) {
            return new FieldReference('DHS_Case__c', fieldPath.substringAfter('.'));
        }
        if (fieldPath.startsWith('DHS_Contact__r.')) {
            return new FieldReference('DHS_Contact__c', fieldPath.substringAfter('.'));
        }
        return null;
    }

    private static String renderElement(Map<String, Object> element, Map<String, Object> caseMap, List<Map<String, Object>> leadMaps) {
        String scope = getString(element, 'scope', 'case');
        if (scope == 'lead') {
            List<String> htmlParts = new List<String>();
            for (Map<String, Object> leadMap : leadMaps) {
                if (!matchesLeadType(element, leadMap) || !conditionsPass(element, caseMap, leadMap)) {
                    continue;
                }
                htmlParts.add(renderElementForContext(element, caseMap, leadMap));
            }
            return String.join(htmlParts, '');
        }
        if (!conditionsPass(element, caseMap, null)) {
            return '';
        }
        return renderElementForContext(element, caseMap, null);
    }

    private static Boolean shouldRenderElement(Map<String, Object> element, Map<String, Object> caseMap, List<Map<String, Object>> leadMaps, Map<String, Object> selectedLeadMap) {
        if (selectedLeadMap != null) {
            String scope = getString(element, 'scope', 'case');
            if (scope == 'lead') {
                return matchesLeadTemplate(element, selectedLeadMap) && conditionsPass(element, caseMap, selectedLeadMap);
            }
            return conditionsPass(element, caseMap, selectedLeadMap);
        }

        String scope = getString(element, 'scope', 'case');
        if (scope == 'lead') {
            for (Map<String, Object> leadMap : leadMaps) {
                if (matchesLeadType(element, leadMap) && conditionsPass(element, caseMap, leadMap)) {
                    return true;
                }
            }
            return false;
        }
        return conditionsPass(element, caseMap, null);
    }

    private static String renderElementForSelectedLead(Map<String, Object> element, Map<String, Object> caseMap, Map<String, Object> leadMap) {
        String scope = getString(element, 'scope', 'case');
        if (scope == 'lead') {
            if (!matchesLeadTemplate(element, leadMap) || !conditionsPass(element, caseMap, leadMap)) {
                return '';
            }
            return renderElementForContext(element, caseMap, leadMap);
        }
        if (!conditionsPass(element, caseMap, leadMap)) {
            return '';
        }
        return renderElementForContext(element, caseMap, leadMap);
    }

    private static String renderElementForContext(Map<String, Object> element, Map<String, Object> caseMap, Map<String, Object> leadMap) {
        String type = getString(element, 'type', 'text');
        String align = getString(element, 'alignment', 'left');
        String fontSize = getString(element, 'fontSize', '14');
        Integer x = getInteger(element, 'x', 72);
        Integer y = getInteger(element, 'y', 72);
        Integer width = getInteger(element, 'width', 360);
        Integer height = getInteger(element, 'height', 60);
        String style = 'left:' + x + 'px;top:' + y + 'px;width:' + width + 'px;height:' + height + 'px;text-align:' + escapeAttribute(align) + ';font-size:' + escapeAttribute(fontSize) + 'px;';
        style += 'border:' + blockBorder(element) + ';padding:' + Math.max(0, Math.min(40, getInteger(element, 'padding', 6))) + 'px;';
        if (getBoolean(element, 'bold')) {
            style += 'font-weight:bold;';
        }
        if (getBoolean(element, 'italic')) {
            style += 'font-style:italic;';
        }
        if (getBoolean(element, 'uppercase')) {
            style += 'text-transform:uppercase;';
        }

        String body;
        if (type == 'section') {
            body = sanitizeRichText(resolveTemplate(element, caseMap, leadMap, 'Section'));
            return wrapPreviewBlock(body, style);
        }
        if (type == 'group') {
            body = sanitizeRichText(resolveTemplate(element, caseMap, leadMap, 'Group'));
            return wrapPreviewBlock(body, style);
        }
        if (type == 'divider') {
            return wrapPreviewBlock('<hr/>', style);
        }
        if (type == 'spacer') {
            return '';
        }
        if (type == 'pageBreak') {
            return '';
        }
        if (type == 'signature') {
            String label = sanitizeRichText(resolveTemplate(element, caseMap, leadMap, 'Signature'));
            return wrapPreviewBlock('<div class="roi-signature"><span>' + label + '</span></div>', style);
        }
        if (type == 'field') {
            String label = getString(element, 'label', '');
            String fieldPath = getString(element, 'fieldPath', '');
            String value = resolveField(fieldPath, caseMap, leadMap);
            if (isBlankOrZero(value)) {
                return '';
            }
            body = '<p><strong>' + escapeHtml(label) + '</strong>' + (String.isBlank(label) ? '' : ': ') + escapeHtml(value) + '</p>';
            return wrapPreviewBlock(body, style);
        }
        if (type == 'table') {
            return wrapPreviewBlock(renderTable(element, caseMap, leadMap), style);
        }
        body = sanitizeRichText(resolveTemplate(element, caseMap, leadMap, '')).replace('\n', '<br/>');
        return wrapPreviewBlock(body, style);
    }

    private static String wrapPreviewBlock(String body, String style) {
        return '<div class="roi-preview-block" style="' + style + '">' + body + '</div>';
    }

    private static String renderTable(Map<String, Object> element, Map<String, Object> caseMap, Map<String, Object> leadMap) {
        List<Object> rowsConfig = (List<Object>) element.get('tableRows');
        if (rowsConfig == null || rowsConfig.isEmpty()) {
            List<Object> fields = (List<Object>) element.get('fields');
            rowsConfig = new List<Object>();
            if (fields != null) {
                for (Object fieldObj : fields) {
                    rowsConfig.add(new Map<String, Object>{ 'fieldPath' => String.valueOf(fieldObj) });
                }
            }
        }

        if (rowsConfig.isEmpty()) {
            return '';
        }
        String tableStyle = tableStyle(element);
        String cellStyle = tableCellStyle(element);
        List<String> rows = new List<String>{ '<table class="roi-preview-table" style="' + tableStyle + '"><tbody>' };
        String headerLabel = getString(element, 'tableHeaderLabel', '');
        String headerValue = getString(element, 'tableHeaderValue', '');
        if (String.isNotBlank(headerLabel) || String.isNotBlank(headerValue)) {
            rows.add('<tr><th style="' + cellStyle + '">' + escapeHtml(headerLabel) + '</th><th style="' + cellStyle + '">' + escapeHtml(headerValue) + '</th></tr>');
        }
        for (Object rowObj : rowsConfig) {
            Map<String, Object> rowConfig = (Map<String, Object>) rowObj;
            if (!conditionsPass(rowConfig, caseMap, leadMap)) {
                continue;
            }
            String fieldPath = getString(rowConfig, 'fieldPath', '');
            String rowLabel = getString(rowConfig, 'label', '');
            if (String.isBlank(rowLabel)) {
                rowLabel = labelFromFieldPath(fieldPath);
            }
            String value = resolveField(fieldPath, caseMap, leadMap);
            if (isBlankOrZero(value)) {
                continue;
            }
            rows.add('<tr><th style="' + cellStyle + '">' + escapeHtml(rowLabel) + '</th><td style="' + cellStyle + '">' + escapeHtml(value) + '</td></tr>');
        }
        if (rows.size() == 1 || (rows.size() == 2 && (String.isNotBlank(headerLabel) || String.isNotBlank(headerValue)))) {
            return '';
        }
        rows.add('</tbody></table>');
        return String.join(rows, '');
    }

    private static String tableStyle(Map<String, Object> element) {
        String border = tableBorder(element);
        Integer padding = Math.max(0, Math.min(40, getInteger(element, 'tableCellPadding', 4)));
        return 'border-collapse:collapse;width:100%;border:' + border + ';--roi-table-border:' + border + ';--roi-table-padding:' + padding + 'px;';
    }

    private static String tableCellStyle(Map<String, Object> element) {
        Integer padding = Math.max(0, Math.min(40, getInteger(element, 'tableCellPadding', 4)));
        return 'border:' + tableBorder(element) + ';padding:' + padding + 'px 8px;text-align:left;';
    }

    private static Boolean isBlankOrZero(String value) {
        if (String.isBlank(value)) {
            return true;
        }
        String normalized = value.trim();
        if (normalized == '0') {
            return true;
        }
        try {
            Decimal numericValue = Decimal.valueOf(normalized.replace(',', ''));
            return numericValue == 0;
        } catch (Exception ignored) {
            return false;
        }
    }

    private static String tableBorder(Map<String, Object> element) {
        String style = getString(element, 'tableBorderStyle', 'solid').toLowerCase();
        Set<String> allowedStyles = new Set<String>{ 'solid', 'dashed', 'dotted', 'double', 'none' };
        if (!allowedStyles.contains(style)) {
            style = 'solid';
        }
        Integer width = Math.max(0, Math.min(12, getInteger(element, 'tableBorderWidth', 1)));
        if (style == 'none' || width == 0) {
            return '0';
        }
        return String.valueOf(width) + 'px ' + style + ' ' + safeCssColor(getString(element, 'tableBorderColor', '#999999'));
    }

    private static String blockBorder(Map<String, Object> element) {
        String style = getString(element, 'borderStyle', 'none').toLowerCase();
        Set<String> allowedStyles = new Set<String>{ 'solid', 'dashed', 'dotted', 'double', 'none' };
        if (!allowedStyles.contains(style)) {
            style = 'none';
        }
        Integer width = Math.max(0, Math.min(12, getInteger(element, 'borderWidth', 0)));
        if (style == 'none' || width == 0) {
            return '0';
        }
        return String.valueOf(width) + 'px ' + style + ' ' + safeCssColor(getString(element, 'borderColor', '#999999'));
    }

    private static String safeCssColor(String value) {
        if (String.isBlank(value)) {
            return '#999999';
        }
        String color = value.trim();
        Pattern colorPattern = Pattern.compile('^#[0-9a-fA-F]{6}$');
        return colorPattern.matcher(color).matches() ? color : '#999999';
    }

    private static Boolean matchesLeadType(Map<String, Object> element, Map<String, Object> leadMap) {
        String leadType = getString(element, 'leadType', '');
        return String.isBlank(leadType) || leadType == String.valueOf(leadMap.get('LeadType__c'));
    }

    private static Boolean matchesLeadTemplate(Map<String, Object> element, Map<String, Object> leadMap) {
        String leadType = getString(element, 'leadType', '');
        String coverageType = getString(element, 'coverageType', '');
        Boolean leadTypeMatches = String.isBlank(leadType) || leadType == String.valueOf(leadMap.get('LeadType__c'));
        Boolean coverageMatches = String.isBlank(coverageType) || coverageType == String.valueOf(leadMap.get('Coverage_Type__c'));
        return leadTypeMatches && coverageMatches;
    }

    private static Boolean conditionsPass(Map<String, Object> element, Map<String, Object> caseMap, Map<String, Object> leadMap) {
        List<Object> conditions = (List<Object>) element.get('conditions');
        if (conditions == null || conditions.isEmpty()) {
            return true;
        }

        String logic = getString(element, 'conditionLogic', 'all');
        Boolean anyMatched = false;
        for (Object conditionObj : conditions) {
            Map<String, Object> condition = (Map<String, Object>) conditionObj;
            String fieldPath = getString(condition, 'fieldPath', '');
            String operator = getString(condition, 'operator', 'is not blank');
            String expected = getString(condition, 'value', '').trim();
            String actual = resolveField(fieldPath, caseMap, leadMap).trim();
            String expectedLower = expected.toLowerCase();
            String actualLower = actual.toLowerCase();

            Boolean matched = conditionMatches(operator, actual, actualLower, expectedLower);

            if (logic == 'any' && matched) {
                return true;
            }
            if (logic != 'any' && !matched) {
                return false;
            }
            anyMatched = anyMatched || matched;
        }
        return logic == 'any' ? anyMatched : true;
    }

    private static Boolean conditionMatches(String operator, String actual, String actualLower, String expectedLower) {
        if (operator == 'is blank') {
            return String.isBlank(actual);
        }
        if (operator == 'is not blank') {
            return String.isNotBlank(actual);
        }
        if (operator == 'equals') {
            return actualLower == expectedLower;
        }
        if (operator == 'not equals') {
            return actualLower != expectedLower;
        }
        if (operator == 'contains') {
            return actualLower.contains(expectedLower);
        }
        return true;
    }

    private static String resolveTemplate(String template, Map<String, Object> caseMap, Map<String, Object> leadMap) {
        if (String.isBlank(template)) {
            return '';
        }
        Pattern tokenPattern = Pattern.compile('\\{([A-Za-z0-9_\\.]+)\\}');
        Matcher matcher = tokenPattern.matcher(template);
        String result = template;
        while (matcher.find()) {
            String token = matcher.group(1);
            result = result.replace('{' + token + '}', escapeHtml(resolveField(token, caseMap, leadMap)));
        }
        return result;
    }

    private static String resolveTemplate(Map<String, Object> element, Map<String, Object> caseMap, Map<String, Object> leadMap, String defaultText) {
        String result = resolveTemplate(getString(element, 'text', defaultText), caseMap, leadMap);
        List<Object> tokens = (List<Object>) element.get('tokens');
        if (tokens == null) {
            return result;
        }
        for (Object tokenObj : tokens) {
            Map<String, Object> token = (Map<String, Object>) tokenObj;
            String label = getString(token, 'label', '');
            String fieldPath = getString(token, 'fieldPath', '');
            if (String.isNotBlank(label) && String.isNotBlank(fieldPath)) {
                result = result.replace('{{' + label + '}}', escapeHtml(resolveField(fieldPath, caseMap, leadMap)));
            }
        }
        return result;
    }

    private static String resolveField(String fieldPath, Map<String, Object> caseMap, Map<String, Object> leadMap) {
        if (String.isBlank(fieldPath)) {
            return '';
        }
        String cleanPath = fieldPath.trim();
        if (cleanPath.startsWith('Context.')) {
            return formatValue(getMapValueIgnoreCase(activeRenderContext, cleanPath.substringAfter('.')));
        }
        if (cleanPath.startsWith('DHS_Case__c.')) {
            return formatValue(getMapValueIgnoreCase(caseMap, cleanPath.substringAfter('.')));
        }
        if (cleanPath.startsWith('DHS_Contact__r.')) {
            return formatValue(getMapValueIgnoreCase(caseMap, cleanPath));
        }
        if (cleanPath.startsWith('DHS_Lead__c.') && leadMap != null) {
            return formatValue(getMapValueIgnoreCase(leadMap, cleanPath.substringAfter('.')));
        }
        return '';
    }

    private static Object getMapValueIgnoreCase(Map<String, Object> valuesByField, String fieldName) {
        if (valuesByField == null || String.isBlank(fieldName)) {
            return null;
        }
        if (valuesByField.containsKey(fieldName)) {
            return valuesByField.get(fieldName);
        }
        String lowerFieldName = fieldName.toLowerCase();
        if (valuesByField.containsKey(lowerFieldName)) {
            return valuesByField.get(lowerFieldName);
        }
        return null;
    }

    private static Map<String, Object> flattenRecord(SObject record) {
        Map<String, Object> flattened = new Map<String, Object>();
        if (record == null) {
            return flattened;
        }
        Map<String, Object> raw = record.getPopulatedFieldsAsMap();
        for (String key : raw.keySet()) {
            Object value = raw.get(key);
            if (value instanceof SObject) {
                Map<String, Object> child = ((SObject) value).getPopulatedFieldsAsMap();
                for (String childField : child.keySet()) {
                    String childPath = key + '.' + childField;
                    flattened.put(childPath, child.get(childField));
                    flattened.put(childPath.toLowerCase(), child.get(childField));
                }
            } else {
                flattened.put(key, value);
                flattened.put(key.toLowerCase(), value);
            }
        }
        return flattened;
    }

    private static String formatValue(Object value) {
        if (value == null) {
            return '';
        }
        return String.valueOf(value);
    }

    private static String getString(Map<String, Object> source, String key, String defaultValue) {
        Object value = source == null ? null : source.get(key);
        return value == null ? defaultValue : String.valueOf(value);
    }

    private static Boolean getBoolean(Map<String, Object> source, String key) {
        Object value = source == null ? null : source.get(key);
        if (value == null) {
            return false;
        }
        return String.valueOf(value).toLowerCase() == 'true';
    }

    private static Integer getInteger(Map<String, Object> source, String key, Integer defaultValue) {
        Object value = source == null ? null : source.get(key);
        if (value == null) {
            return defaultValue;
        }
        try {
            return Integer.valueOf(String.valueOf(value));
        } catch (Exception ex) {
            return defaultValue;
        }
    }

    private static String escapeHtml(String value) {
        if (value == null) {
            return '';
        }
        return value
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;')
            .replace('\'', '&#39;');
    }

    private static String escapeAttribute(String value) {
        return escapeHtml(value).replace(';', '');
    }

    private static String labelFromFieldPath(String fieldPath) {
        String cacheKey = String.isBlank(fieldPath) ? '' : fieldPath.trim().toLowerCase();
        if (labelByFieldPath.containsKey(cacheKey)) {
            return labelByFieldPath.get(cacheKey);
        }
        if (!String.isBlank(fieldPath) && fieldPath.trim().startsWith('Context.')) {
            for (FieldOption option : getContextFieldOptions()) {
                if (option.value.toLowerCase() == fieldPath.trim().toLowerCase()) {
                    labelByFieldPath.put(cacheKey, option.label);
                    return option.label;
                }
            }
        }
        Schema.DescribeFieldResult describeField = describeFieldPath(fieldPath);
        String label = describeField == null ? fieldPath : describeField.getLabel();
        labelByFieldPath.put(cacheKey, label);
        return label;
    }

    private static Map<String, Schema.SObjectField> getFieldMap(String objectName) {
        if (!fieldMapByObject.containsKey(objectName)) {
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
            fieldMapByObject.put(objectName, objectType == null ? new Map<String, Schema.SObjectField>() : objectType.getDescribe().fields.getMap());
        }
        return fieldMapByObject.get(objectName);
    }

    private static Map<String, String> getFieldApiByLower(String objectName) {
        if (!fieldApiByLowerByObject.containsKey(objectName)) {
            Map<String, String> lowerToApi = new Map<String, String>();
            for (String apiName : getFieldMap(objectName).keySet()) {
                lowerToApi.put(apiName.toLowerCase(), apiName);
            }
            fieldApiByLowerByObject.put(objectName, lowerToApi);
        }
        return fieldApiByLowerByObject.get(objectName);
    }

    private static String sanitizeRichText(String value) {
        if (String.isBlank(value)) {
            return '';
        }
        String safe = value;
        safe = safe.replaceAll('(?is)<script[^>]*>.*?</script>', '');
        safe = safe.replaceAll('(?i)\\son[a-z]+\\s*=\\s*"[^"]*"', '');
        safe = safe.replaceAll('(?i)\\son[a-z]+\\s*=\\s*[^\\s>]+', '');
        safe = safe.replaceAll('(?i)javascript\\s*:', '');
        return safe;
    }

    private static Map<String, Object> summaryCountRow(String label, String fieldPath) {
        return new Map<String, Object>{
            'label' => label,
            'fieldPath' => fieldPath,
            'conditionLogic' => 'all',
            'conditions' => new List<Object>{
                new Map<String, Object>{ 'fieldPath' => fieldPath, 'operator' => 'not equals', 'value' => '0' }
            }
        };
    }

    private static String defaultConfig(String leadType, String coverageType) {
        Map<String, Object> config = new Map<String, Object>();
        config.put('version', 1);
        config.put('name', 'ROI Template - ' + String.valueOf(leadType) + ' - ' + String.valueOf(coverageType));
        config.put('leadType', leadType);
        config.put('coverageType', coverageType);
        if (leadType == 'Header') {
            config.put('elements', new List<Object>{
                new Map<String, Object>{
                    'id' => 'header-address',
                    'type' => 'text',
                    'text' => '<p><b>TO:</b> &nbsp;&nbsp; {{Case: PPF Customer Contact Name}}<br/>Department of Defense<br/>9800 Savage Road Suite: 6381, A5231<br/>Ft. Meade, MD 20755-6774</p><p><b>FROM:</b> &nbsp;&nbsp; Information Systems &amp; Networks Corporation<br/>10411 Motor City Dr, Suite 700<br/>Bethesda, MD 20817</p>',
                    'scope' => 'case',
                    'alignment' => 'left',
                    'fontSize' => 16,
                    'bold' => false,
                    'x' => 44,
                    'y' => 40,
                    'width' => 700,
                    'height' => 220,
                    'tokens' => new List<Object>{
                        new Map<String, Object>{ 'label' => 'Case: PPF Customer Contact Name', 'fieldPath' => 'DHS_Case__c.PPF_Customer_Contact_Name__c' }
                    }
                },
                new Map<String, Object>{
                    'id' => 'header-case-lines',
                    'type' => 'text',
                    'text' => '<p><b>CASE NAME:</b> {{Contact: Last Name}}, {{Contact: First Name}} <span style="float:right"><b>SSN:</b> {{Contact: SSN}}</span></p><p><b>CASE Type:</b> {{Case: Case Type}} - {{Case: Subject Type}} <span style="float:right"><b>BI Provider Report#</b> {{Case: Case Number}}</span></p>',
                    'scope' => 'case',
                    'alignment' => 'left',
                    'fontSize' => 16,
                    'bold' => false,
                    'x' => 44,
                    'y' => 300,
                    'width' => 700,
                    'height' => 110,
                    'tokens' => new List<Object>{
                        new Map<String, Object>{ 'label' => 'Contact: Last Name', 'fieldPath' => 'DHS_Contact__r.Last_Name__c' },
                        new Map<String, Object>{ 'label' => 'Contact: First Name', 'fieldPath' => 'DHS_Contact__r.First_Name__c' },
                        new Map<String, Object>{ 'label' => 'Contact: SSN', 'fieldPath' => 'DHS_Contact__r.SSN__c' },
                        new Map<String, Object>{ 'label' => 'Case: Case Type', 'fieldPath' => 'DHS_Case__c.Case_Type__c' },
                        new Map<String, Object>{ 'label' => 'Case: Subject Type', 'fieldPath' => 'DHS_Case__c.Subject_Type__c' },
                        new Map<String, Object>{ 'label' => 'Case: Case Number', 'fieldPath' => 'DHS_Case__c.Case_Number__c' }
                    }
                }
            });
            return JSON.serialize(config);
        }
        if (leadType == 'Summary') {
            config.put('elements', new List<Object>{
                new Map<String, Object>{
                    'id' => 'summary-case-heading',
                    'type' => 'text',
                    'text' => '<p><b>Subject Name:</b> {{Case: Subject Name}} <span style="float:right"><b>Case Type:</b> {{Case: Case Type}}</span></p>',
                    'scope' => 'case',
                    'alignment' => 'left',
                    'fontSize' => 16,
                    'bold' => false,
                    'x' => 44,
                    'y' => 32,
                    'width' => 700,
                    'height' => 40,
                    'tokens' => new List<Object>{
                        new Map<String, Object>{ 'label' => 'Case: Subject Name', 'fieldPath' => 'DHS_Case__c.Subject_Name__c' },
                        new Map<String, Object>{ 'label' => 'Case: Case Type', 'fieldPath' => 'DHS_Case__c.Case_Type__c' }
                    }
                },
                new Map<String, Object>{
                    'id' => 'summary-section-counts',
                    'type' => 'table',
                    'scope' => 'case',
                    'x' => 44,
                    'y' => 88,
                    'width' => 700,
                    'height' => 210,
                    'tableHeaderLabel' => 'Section',
                    'tableHeaderValue' => 'Number',
                    'tableBorderStyle' => 'none',
                    'tableBorderWidth' => 0,
                    'tableCellPadding' => 2,
                    'tableRows' => new List<Object>{
                        summaryCountRow('EMPLOYMENT', 'DHS_Case__c.Employment_Count__c'),
                        summaryCountRow('GENERAL', 'DHS_Case__c.General_Count__c'),
                        summaryCountRow('MEDICAL', 'DHS_Case__c.Medical_Count__c'),
                        summaryCountRow('SUBJECT INTERVIEW', 'DHS_Case__c.Subject_Interview_Count__c'),
                        summaryCountRow('ATTACHMENTS', 'DHS_Case__c.Attachment_Count__c'),
                        summaryCountRow('TOTAL REFERENCES', 'DHS_Case__c.Total_References_Count__c')
                    }
                },
                new Map<String, Object>{
                    'id' => 'summary-results',
                    'type' => 'text',
                    'text' => '<p><b>RESULTS</b><br/>All records obtained.<br/>All sources recommend.</p>',
                    'scope' => 'case',
                    'alignment' => 'left',
                    'fontSize' => 16,
                    'bold' => false,
                    'x' => 44,
                    'y' => 324,
                    'width' => 700,
                    'height' => 90
                }
            });
            return JSON.serialize(config);
        }
        if (leadType == 'Report Table') {
            config.put('elements', new List<Object>{
                new Map<String, Object>{
                    'id' => 'report-table-title',
                    'type' => 'section',
                    'text' => 'REPORT OF INVESTIGATION',
                    'scope' => 'case',
                    'alignment' => 'center',
                    'fontSize' => 18,
                    'bold' => true,
                    'x' => 120,
                    'y' => 40,
                    'width' => 560,
                    'height' => 50
                },
                new Map<String, Object>{
                    'id' => 'report-table',
                    'type' => 'text',
                    'text' => '<table style="border-collapse:collapse;width:100%;font-size:16px;"><tbody><tr><th style="border:1px solid #555;padding:8px;text-align:left;">{{Case: Subject Name}}</th><th style="border:1px solid #555;padding:8px;text-align:left;">BI Provider Report ID</th><th style="border:1px solid #555;padding:8px;text-align:left;">Investigation Dates</th><th style="border:1px solid #555;padding:8px;text-align:left;">Investigators</th></tr><tr><td style="border:1px solid #555;padding:8px;">SSN: {{Contact: SSN}}</td><td style="border:1px solid #555;padding:8px;">{{Case: Case Number}}</td><td style="border:1px solid #555;padding:8px;">{{Case: Investigations Date}} to N/A</td><td style="border:1px solid #555;padding:8px;">{{Case: Assigned To Name}}</td></tr></tbody></table>',
                    'scope' => 'case',
                    'alignment' => 'left',
                    'fontSize' => 16,
                    'bold' => false,
                    'x' => 44,
                    'y' => 104,
                    'width' => 700,
                    'height' => 160,
                    'tokens' => new List<Object>{
                        new Map<String, Object>{ 'label' => 'Case: Subject Name', 'fieldPath' => 'DHS_Case__c.Subject_Name__c' },
                        new Map<String, Object>{ 'label' => 'Contact: SSN', 'fieldPath' => 'DHS_Contact__r.SSN__c' },
                        new Map<String, Object>{ 'label' => 'Case: Case Number', 'fieldPath' => 'DHS_Case__c.Case_Number__c' },
                        new Map<String, Object>{ 'label' => 'Case: Investigations Date', 'fieldPath' => 'DHS_Case__c.Investigations_Date__c' },
                        new Map<String, Object>{ 'label' => 'Case: Assigned To Name', 'fieldPath' => 'DHS_Case__c.Assigned_To_Name__c' }
                    }
                }
            });
            return JSON.serialize(config);
        }
        config.put('elements', new List<Object>{
            new Map<String, Object>{
                'id' => 'section-summary',
                'type' => 'section',
                'text' => 'REPORT OF INVESTIGATION',
                'scope' => 'case',
                'alignment' => 'center',
                'fontSize' => 18,
                'bold' => true,
                'x' => 120,
                'y' => 40,
                'width' => 560,
                'height' => 50
            },
            new Map<String, Object>{
                'id' => 'lead-notes',
                'type' => 'text',
                'text' => '<p>Lead {{Lead: Item Number}}: {{Lead: Investigators Notes}}</p>',
                'scope' => 'lead',
                'leadType' => leadType,
                'coverageType' => coverageType,
                'alignment' => 'left',
                'fontSize' => 13,
                'bold' => false,
                'x' => 44,
                'y' => 112,
                'width' => 700,
                'height' => 120,
                'tokens' => new List<Object>{
                    new Map<String, Object>{ 'label' => 'Lead: Item Number', 'fieldPath' => 'DHS_Lead__c.Item_number__c' },
                    new Map<String, Object>{ 'label' => 'Lead: Investigators Notes', 'fieldPath' => 'DHS_Lead__c.Investigators_Notes__c' }
                },
                'conditions' => new List<Object>{
                    new Map<String, Object>{ 'fieldPath' => 'DHS_Lead__c.Investigators_Notes__c', 'operator' => 'is not blank', 'value' => '' }
                }
            }
        });
        return JSON.serialize(config);
    }

    private static String sortedJoin(Set<String> fields) {
        Map<String, String> uniqueFields = new Map<String, String>();
        for (String fieldName : fields) {
            if (String.isNotBlank(fieldName) && !uniqueFields.containsKey(fieldName.toLowerCase())) {
                uniqueFields.put(fieldName.toLowerCase(), fieldName);
            }
        }
        List<String> sorted = new List<String>(uniqueFields.values());
        sorted.sort();
        return String.join(sorted, ',');
    }

    private static String configTitleFor(String leadType, String coverageType) {
        String suffix = normalizeTemplateKey(leadType) + '_' + normalizeTemplateKey(coverageType);
        if (suffix == '_') {
            return CONFIG_TITLE;
        }
        return CONFIG_TITLE + '_' + suffix;
    }

    private static String normalizeTemplateKey(String value) {
        if (String.isBlank(value)) {
            return '';
        }
        String normalized = value.trim().replaceAll('[^A-Za-z0-9]+', '_');
        normalized = normalized.replaceAll('^_+', '').replaceAll('_+$', '');
        return normalized.length() > 80 ? normalized.substring(0, 80) : normalized;
    }

    private static Map<String, List<String>> templateCoverageValuesByLeadType() {
        return new Map<String, List<String>>{
            'Public records (PUBR)' => new List<String>{ 'Record', 'General Record' },
            'Law Enforcement (LAWE)' => new List<String>{ 'Record', 'General Record' },
            'General (GENL)' => new List<String>{ 'Record', 'Personal' },
            'Employment (EMPL)' => new List<String>{ 'Record', 'General Record', 'Personal' },
            'Medical (MEDI)' => new List<String>{ 'Record', 'General Record', 'Personal' },
            'Education (EDUC)' => new List<String>{ 'Record', 'General Record', 'Personal' },
            'Financial (FINL)' => new List<String>{ 'Record', 'General Record' },
            'Residence (RESI)' => new List<String>{ 'General Record', 'Record', 'Personal' },
            'Unemployment' => new List<String>{ 'General Record', 'Record', 'Personal' },
            'References (REFE)' => new List<String>{ 'Personal' },
            'Former Spouse (FMSP)' => new List<String>{ 'Personal' },
            'Subject Interview (ESI/TESI)' => new List<String>{ 'Subject Interview' },
            'Subject Recontact (SUBC)' => new List<String>{ 'Subject Recontact' }
        };
    }

    private static Boolean isCaseLevelTemplate(String leadType) {
        return caseLevelTemplateNames().contains(leadType);
    }

    private static List<String> caseLevelTemplateNames() {
        return new List<String>{ 'Header', 'Disclaimer', 'PAEI', 'Summary', 'Report Table' };
    }

    private static List<String> leadContextTemplateNames() {
        return new List<String>{ 'Disclaimer', 'PAEI' };
    }
}
