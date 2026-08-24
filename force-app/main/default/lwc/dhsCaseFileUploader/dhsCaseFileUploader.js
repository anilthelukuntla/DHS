import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseFileUploader extends LightningElement {
    @api recordId;

    @track selectedFiles = [];
    @track isUploading = false;
    @track uploadedCount = 0;
    @track showSuccessMessage = false;

    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg', '.docx'];
    }

    handleFileSelection(event) {
        const files = Array.from(event.target.files);
        this.selectedFiles = files.map(file => ({
            name: file.name,
            size: this.formatFileSize(file.size),
            type: file.type,
            file: file
        }));
        this.showSuccessMessage = false;
    }

    formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    clearSelection() {
        this.selectedFiles = [];
        this.uploadedCount = 0;
        this.showSuccessMessage = false;
        const fileInput = this.template.querySelector('#fileInput');
        if (fileInput) {
            fileInput.value = '';
        }
    }

    async handleUpload() {
        if (this.selectedFiles.length === 0) {
            this.showToast('Error', 'Please select files to upload', 'error');
            return;
        }

        this.isUploading = true;
        this.uploadedCount = 0;
        this.showSuccessMessage = false;

        try {
            // Upload files using REST API approach (like working Visualforce pages)
            const uploadPromises = this.selectedFiles.map(async (fileInfo) => {
                const file = fileInfo.file;
                
                return new Promise((resolve, reject) => {
                    const reader = new FileReader();
                    reader.onload = () => {
                        const base64 = reader.result.split(',')[1];
                        
                        // Use REST API approach for large files
                        this.uploadFileViaREST(file.name, file.type, base64)
                            .then(result => {
                                this.uploadedCount++;
                                console.log('File uploaded:', file.name, 'Result:', result);
                                resolve(result);
                            })
                            .catch(error => {
                                console.error('Upload error for file:', file.name, error);
                                reject(error);
                            });
                    };
                    reader.readAsDataURL(file);
                });
            });

            // Wait for all uploads to complete
            await Promise.all(uploadPromises);

            this.showSuccessMessage = true;
            this.showToast('Success', `${this.selectedFiles.length} files uploaded successfully!`, 'success');
            
            // Clear selection after successful upload
            setTimeout(() => {
                this.clearSelection();
            }, 2000);

        } catch (error) {
            console.error('Upload failed:', error);
            this.showToast('Error', 'Upload failed: ' + error.message, 'error');
        } finally {
            this.isUploading = false;
        }
    }

    uploadFileViaREST(fileName, contentType, base64Data) {
        return new Promise((resolve, reject) => {
            // Create ContentVersion record
            const contentVersion = {
                Title: fileName,
                PathOnClient: fileName,
                VersionData: base64Data,
                ContentLocation: 'S'
            };

            // Use fetch API to call Salesforce REST API
            fetch('/services/data/v58.0/sobjects/ContentVersion', {
                method: 'POST',
                headers: {
                    'Authorization': 'Bearer ' + this.getSessionId(),
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(contentVersion)
            })
            .then(response => response.json())
            .then(result => {
                if (result.id) {
                    // Create ContentDocumentLink to associate with the case
                    return this.createContentDocumentLink(result.id);
                } else {
                    throw new Error('Failed to create ContentVersion: ' + JSON.stringify(result));
                }
            })
            .then(linkResult => {
                resolve(linkResult);
            })
            .catch(error => {
                console.error('REST API upload error:', error);
                reject(error);
            });
        });
    }

    createContentDocumentLink(contentDocumentId) {
        return new Promise((resolve, reject) => {
            const linkData = {
                ContentDocumentId: contentDocumentId,
                LinkedEntityId: this.recordId,
                ShareType: 'V'
            };

            fetch('/services/data/v58.0/sobjects/ContentDocumentLink', {
                method: 'POST',
                headers: {
                    'Authorization': 'Bearer ' + this.getSessionId(),
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(linkData)
            })
            .then(response => response.json())
            .then(result => {
                resolve(result);
            })
            .catch(error => {
                console.error('ContentDocumentLink creation error:', error);
                reject(error);
            });
        });
    }

    getSessionId() {
        // Get session ID from the Visualforce page context
        // This will be set by the parent page
        return window.sfdcSessionId || 
               document.cookie.match(/sid=([^;]+)/)?.[1] ||
               this.getCookie('sid');
    }

    getCookie(name) {
        const value = `; ${document.cookie}`;
        const parts = value.split(`; ${name}=`);
        if (parts.length === 2) return parts.pop().split(';').shift();
        return null;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}