import { LightningElement, api, track } from 'lwc';
import fetchRecords from '@salesforce/apex/DIATooling.fetchRecords';
import fetchNextBatch from '@salesforce/apex/DIATooling.fetchNext';
import getFieldMappings from '@salesforce/apex/DHSCDRLReportsController.getFieldMap';

export default class ExportCSV extends LightningElement {
    @api sObjectName;
    @api selectedFields = [];
    @api queryConditions;
    @api sortBy = null;
    @api reportType;
    @api fieldNames;
    loading = false;
    downloadedData = [];
    nextBatchUrl = "";
    fieldMappings = [];
    fieldApiNames = [];
    columnLabels = [];

    // Fetches field mappings when component is initialized
    connectedCallback() {
        console.log("@@@@@@@@@@@@@@@@@");
        getFieldMappings({ reportType: this.reportType }).then(response => {
            this.loading = true;
            
            response.forEach(field => {
                this.fieldApiNames.push(field.apiname);
                this.columnLabels.push(field.label);
            });
            this.fetchData();

        }).catch(error => {
            console.error(error);
        });
    }

    // Fetches data based on given criteria and handles pagination
    fetchData() {
        let fetchFunction = null;
        if (this.nextBatchUrl) {
            fetchFunction = fetchNextBatch({ 'url': this.nextBatchUrl.replace('/services/data/v58.0/query', '') });
        } else {
            let requestPayload = { sObjectName: this.sObjectName, fieldNames: this.fieldApiNames, conditions: this.queryConditions, querylimit: null, orderBy: this.sortBy };
            fetchFunction = fetchRecords(requestPayload);
        }

        fetchFunction.then(response => {
            response = JSON.parse(response);
            if (!response.records) {
                this.loading = false;
            } else {
                this.downloadedData = this.downloadedData.concat(response.records);
                if (response.nextRecordsUrl) {
                    this.nextBatchUrl = response.nextRecordsUrl;
                    this.fetchData();
                } else {
                    this.downloadCSV(this.columnLabels, this.downloadedData, 'data');
                    this.loading = false;
                }
            }
        }).catch(error => { 
            console.error(error); 
        });
    }

    // Converts data to CSV and triggers download
    downloadCSV(headers, data, fileTitle) {
        if (!data || !data.length) {
            return null;
        }
        const jsonData = JSON.stringify(data);
        const csvData = this.convertToCSV(jsonData, headers);
        
        if (csvData === null) return;
        
        const blob = new Blob([csvData]);
        const filename = `DashBoardChartExport ${fileTitle ? fileTitle + '.csv' : 'DashBoardChartExport.csv'}`;
        
        if (navigator.msSaveBlob) {
            navigator.msSaveBlob(blob, filename);
        } else if (navigator.userAgent.match(/iPhone|iPad|iPod/i)) {
            const link = window.document.createElement('a');
            link.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvData);
            link.target = "_blank";
            link.download = filename;
            link.click();
        } else {
            const link = document.createElement("a");
            if (link.download !== undefined) {
                const url = URL.createObjectURL(blob);
                link.setAttribute("href", url);
                link.setAttribute("download", filename);
                link.style.visibility = 'hidden';
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
            }
        }
    }

    // Converts object data to CSV format
    convertToCSV(dataArray, headers) {
        headers = JSON.parse(JSON.stringify(headers));
        const columnDelimiter = ',';
        const lineDelimiter = '\r\n';
        let csvContent = '';

        // Adding headers to CSV
        headers.forEach(header => {
            csvContent += header.replace(/,/g, '') + columnDelimiter;
        });
        csvContent = csvContent.slice(0, -1) + lineDelimiter;

        const dataObjects = typeof dataArray !== 'object' ? JSON.parse(dataArray) : dataArray;

        // Flatten nested data
        const flattenObject = (obj, roots = [], sep = '.') => 
            Object.keys(obj).reduce((acc, key) => Object.assign(
                {},
                acc,
                Object.prototype.toString.call(obj[key]) === '[object Object]'
                    ? flattenObject(obj[key], roots.concat([key]), sep)
                    : { [roots.concat([key]).join(sep)]: obj[key] }
            ), {});

        let flattenedData = dataObjects.map(obj => flattenObject(obj));

        // Adding rows to CSV
        flattenedData.forEach(data => {
            let row = '';
            this.fieldApiNames.forEach((key, index) => {
                if (index > 0) {
                    row += columnDelimiter;
                }

                let cellValue = (data[key.apiname] || data[key] || '') + '';
                if ((key === 'Case_Queue_Status__c' && cellValue === 'New') || (key === 'Case_Queue_Status__c' && cellValue === 'Assigned') || (key === 'Status__c' && cellValue === 'Assigned Not Accepted') || (key === 'Status__c' && cellValue === 'Assigned') || (key === 'Status__c' && cellValue === 'Unassigned')) {
                    cellValue = 'In-Progress';
                }

                cellValue = cellValue.replace(/[,;\n\r]/g, ' ');
                row += cellValue;
            });
            csvContent += row + lineDelimiter;
        });

        return csvContent;
    }
}