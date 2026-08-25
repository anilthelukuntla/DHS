import { LightningElement, api, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import pdfLib from '@salesforce/resourceUrl/pdf_lib';

export default class CaseDocumentPdfMerger extends LightningElement {
    @api recordId;
    @api documentData;
    @api subjectType; // New property for Subject Type (Applicant/Contractor)
    @api socialSecurityNumber; // New property for SSN
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
                    this.processDocumentData();
                })
                .catch(error => {
                    console.error('Failed to load pdf-lib:', error);
                });
        }
    }

    processDocumentData() {
        if (!this.documentData || this.documentData.length === 0) {
            console.error('No document data provided');
            return;
        }

        console.log('=== LWC: RECEIVED DOCUMENT DATA ===');
        console.log('Total received:', this.documentData.length);
        this.documentData.forEach((doc, index) => {
            console.log(`Document ${index + 1}: "${doc.title}" - Sequence: ${doc.sequence} - Has Base64: ${!!doc.base64Data}`);
        });

        // Process only documents that have a sequence selected and base64 data
        this.documents = this.documentData
            .filter(doc => {
                const hasSequence = doc.sequence !== undefined && doc.sequence !== null && doc.sequence >= 0;
                const hasBase64 = doc.base64Data;
                return hasSequence && hasBase64;
            })
            .map(doc => {
                console.log(`✓ Including "${doc.title}" - Sequence: ${doc.sequence} - Base64 Length: ${doc.base64Data ? doc.base64Data.length : 'N/A'}`);
                return {
                    AttachmentId: doc.attachmentId,
                    Title: doc.title,
                    AddedBy: doc.addedBy,
                    Notes: doc.notes,
                    Sequence: doc.sequence,
                    Base64Data: doc.base64Data
                };
            });
        console.log('Documents after filtering:', this.documents.length);

        if (this.documents.length === 0) {
            
            return;
        }

        this.handleMergeAndDownload();
    }

    handleMergeAndDownload() {
        if (this.documents.length === 0) {
            
            return;
        }

        const sorted = [...this.documents].sort((a, b) => a.Sequence - b.Sequence);
        console.log('=== LWC: SORTED DOCUMENTS ===');
        sorted.forEach((doc, index) => {
            console.log(`${index + 1}. "${doc.Title}" - Sequence: ${doc.Sequence} - Base64 Length: ${doc.Base64Data ? doc.Base64Data.length : 'N/A'}`);
        });
        
        const base64List = sorted.map(doc => doc.Base64Data);
        console.log('Base64 list length:', base64List.length);
        
        const validBase64List = base64List.filter(base64 => base64);
        console.log('Valid base64 list length:', validBase64List.length);
        
        if (validBase64List.length === 0) {
            
            this.loading = false;
            return;
        }

        console.log('=== LWC: STARTING PDF MERGE ===');
        this.mergePDFs(validBase64List, sorted);
    }

    async mergePDFs(base64List, sortedDocuments) {
        try {
            if (!window.PDFLib) {
                throw new Error('PDFLib not loaded');
            }

            const { PDFDocument, rgb } = window.PDFLib;
            const mergedPdf = await PDFDocument.create();
            let pagesAdded = 0;
            let processedCount = 0;
            const pageRanges = [];

            for (let i = 0; i < base64List.length; i++) {
                const base64 = base64List[i];
                console.log(`Processing document ${i + 1}: "${sortedDocuments[i].Title}" - Sequence: ${sortedDocuments[i].Sequence}`);
                console.log(`Base64 data length: ${base64 ? base64.length : 'null'}`);
                
                if (!base64 || typeof base64 !== 'string') {
                    console.log(`Skipping document ${i + 1} - no valid base64 data`);
                    continue;
                }

                try {
                    const binaryString = atob(base64);
                    const bytes = new Uint8Array(binaryString.length);
                    for (let j = 0; j < binaryString.length; j++) {
                        bytes[j] = binaryString.charCodeAt(j);
                    }

                    // Validate PDF header
                    const header = new TextDecoder().decode(bytes.slice(0, 8));
                    if (!header.startsWith('%PDF-')) {
                        throw new Error(`Invalid PDF header: ${header}. Document may not be a valid PDF file.`);
                    }

                    const pdf = await PDFDocument.load(bytes, {
                        ignoreEncryption: true,
                        updateMetadata: false
                    });

                    const pageCount = pdf.getPageCount();
                    console.log(`Document ${i + 1} has ${pageCount} pages`);
                    
                    if (pageCount > 0) {
                        const copiedPages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());
                        copiedPages.forEach(page => mergedPdf.addPage(page));
                        
                        // Track page range for this document
                        const startPage = pagesAdded + 1;
                        const endPage = pagesAdded + pageCount;
                        pageRanges.push({
                            title: sortedDocuments[i].Title,
                            startPage: startPage,
                            endPage: endPage
                        });
                        
                        pagesAdded += pageCount;
                        processedCount++;
                        console.log(`✓ Successfully added document ${i + 1}: "${sortedDocuments[i].Title}" (pages ${startPage}-${endPage})`);
                    } else {
                        console.log(`Document ${i + 1} has no pages, skipping`);
                    }
                } catch (err) {
                    console.error(`Failed to process PDF at index ${i}: "${sortedDocuments[i].Title}"`, err);
                    console.error(`Document details: Sequence=${sortedDocuments[i].Sequence}, Base64 length=${base64 ? base64.length : 'null'}`);
                    
                    // Show user-friendly error message
                    if (window.$) {
                        $('#loadingOverlay div[style*="font-size: 18px"]').text('Error Processing Document');
                        $('#loadingOverlay div[style*="font-size: 14px"]').text(`Failed to process "${sortedDocuments[i].Title}". This document may be corrupted or not a valid PDF file.`);
                        $('#loadingOverlay .spinner-border').hide();
                        
                        setTimeout(() => {
                            $('#loadingOverlay').hide();
                        }, 5000);
                    }
                }
            }

            if (pagesAdded === 0) {
                console.error('No valid PDF pages were processed. All documents may be corrupted or invalid.');
                if (window.$) {
                    $('#loadingOverlay div[style*="font-size: 18px"]').text('No Valid Documents Found');
                    $('#loadingOverlay div[style*="font-size: 14px"]').text('All selected documents appear to be corrupted or not valid PDF files.');
                    $('#loadingOverlay .spinner-border').hide();
                    
                    setTimeout(() => {
                        $('#loadingOverlay').hide();
                    }, 5000);
                }
                this.loading = false;
                return;
            }

            // Generate filename based on case information
            const filename = this.generateFilename();
            const mergedBytes = await mergedPdf.save();
            this.downloadBlob(mergedBytes, filename);
            
        } catch (error) {
            console.error('Error merging PDFs:', error);
            
       
            setTimeout(() => {
                if (window.$) {
                    window.$('#loadingOverlay').hide();
                }
            }, 6000); 
    
        } finally {
            this.loading = false;
        }
    }

    generateFilename() {
        // Default filename if case information is not available
        if (!this.subjectType || !this.socialSecurityNumber) {
            console.warn('Case information not available, using default filename');
            return 'merged_case_documents.pdf';
        }

        // Get first letter of Subject Type (A for Applicant, C for Contractor)
        let subjectTypeLetter = '';
        if (this.subjectType === 'Applicant') {
            subjectTypeLetter = 'A';
        } else if (this.subjectType === 'Contractor') {
            subjectTypeLetter = 'C';
        } else {
            console.warn('Unknown subject type:', this.subjectType);
            return 'merged_case_documents.pdf';
        }

        // Remove dashes from SSN
        const ssnWithoutDashes = this.socialSecurityNumber.replace(/-/g, '');

        // Generate filename: First letter of Subject Type + SSN without dashes + Att00
        const filename = `${subjectTypeLetter}${ssnWithoutDashes}Att00.pdf`;
        
        console.log('Generated filename:', filename);
        console.log('Subject Type:', this.subjectType);
        console.log('SSN:', this.socialSecurityNumber);
        console.log('SSN without dashes:', ssnWithoutDashes);
        
        return filename;
    }

    downloadBlob(bytes, filename) {
        const blob = new Blob([bytes], { type: 'application/pdf' });
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = filename;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        
        // Hide loading overlay immediately when download starts
        if (window.$) {
            window.$('#loadingOverlay').hide();
        }
    }
}