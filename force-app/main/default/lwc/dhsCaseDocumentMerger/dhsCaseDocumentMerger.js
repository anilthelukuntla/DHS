import { LightningElement, api, track } from 'lwc';
import getDocumentsForCase from '@salesforce/apex/DHSCaseDocumentMergerController.getDocumentsForCase';
import getBase64PDFs from '@salesforce/apex/DHSCaseDocumentMergerController.getBase64PDFs';
import getContentVersionIdsFromAttachments from '@salesforce/apex/DHSCaseDocumentMergerController.getContentVersionIdsFromAttachments';
import { loadScript } from 'lightning/platformResourceLoader';
import pdfLib from '@salesforce/resourceUrl/pdf_lib'; // UMD build of pdf-lib

export default class CaseDocumentMerger extends LightningElement {
    @api recordId;
    @api documentData;
    @track documents = [];
    @track loading = false;

    pdfLibInitialized = false;

    connectedCallback() {
        if (!this.pdfLibInitialized) {
            loadScript(this, pdfLib)
                .then(() => {
                    if (!window.PDFLib) {
                        console.error('PDFLib is not available after loading.');
                        return;
                    }
                    this.pdfLibInitialized = true;
                    console.log('PDFLib successfully loaded.');
                    this.processDocumentData();
                })
                .catch(error => {
                    console.error('Failed to load pdf-lib:', error);
                });
        }
    }

    processDocumentData() {
        if (!this.documentData || this.documentData.length === 0) return;

        const attachmentIds = this.documentData.map(doc => doc.attachmentId);

        getContentVersionIdsFromAttachments({ attachmentIds })
            .then(result => {
                this.documents = this.documentData.map(doc => ({
                    contentVersionId: result[doc.attachmentId],
                    title: doc.title,
                    addedBy: doc.addedBy,
                    notes: doc.notes,
                    sequence: doc.sequence
                }));

                this.handleMergeAndDownload();
            })
            .catch(error => {
                console.error('Error getting ContentVersion IDs:', error);
            });
    }

    handleMergeAndDownload() {
        if (this.documents.length === 0) {
            this.showToast('No documents to merge', 'error');
            return;
        }

        const sorted = [...this.documents].sort((a, b) => a.sequence - b.sequence);
        const ids = sorted.map(doc => doc.contentVersionId);

        this.loading = true;
        getBase64PDFs({ contentVersionIds: ids })
            .then(base64Map => {
                const pdfBytesList = ids.map(id => base64Map[id]);
                this.mergePDFs(pdfBytesList);
            })
            .catch(error => {
                console.error('Error fetching base64 PDFs:', error);
                this.showToast('Error fetching PDFs', 'error');
                this.loading = false;
            });
    }

    async mergePDFs(base64List) {
        const { PDFDocument } = window.PDFLib;

        try {
            const mergedPdf = await PDFDocument.create();

            for (let i = 0; i < base64List.length; i++) {
                const base64 = base64List[i];

                if (!base64 || typeof base64 !== 'string') {
                    console.warn(`Skipping empty or invalid base64 at index ${i}`);
                    continue;
                }

                try {
                    const binary = atob(base64);
                    const bytes = new Uint8Array(binary.length);
                    for (let j = 0; j < binary.length; j++) {
                        bytes[j] = binary.charCodeAt(j);
                    }

                    const pdf = await PDFDocument.load(bytes, { ignoreEncryption: true });
                    const copiedPages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());
                    copiedPages.forEach(page => mergedPdf.addPage(page));
                } catch (err) {
                    console.error(`Failed to process PDF at index ${i}:`, err);
                }
            }

            const mergedBytes = await mergedPdf.save();
            this.downloadBlob(mergedBytes, 'merged_case_documents.pdf');
            this.showToast('PDF merged successfully', 'success');
        } catch (error) {
            console.error('Error merging PDFs:', error);
            this.showToast('Error merging PDFs', 'error');
        } finally {
            this.loading = false;
        }
    }

    downloadBlob(bytes, filename) {
        const blob = new Blob([bytes], { type: 'application/pdf' });
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = filename;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    showToast(message, type) {
        // Replace with lightning toast if needed
        console.log(`${type.toUpperCase()}: ${message}`);
    }
}