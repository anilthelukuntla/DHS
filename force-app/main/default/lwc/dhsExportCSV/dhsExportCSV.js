import { LightningElement, api, track } from 'lwc';
import tooling from '@salesforce/apex/DIATooling.fetchRecords';
import fetchNext from '@salesforce/apex/DIATooling.fetchNext';
import getFieldMap from '@salesforce/apex/DHSgetMetadata.getFieldMap';
export default class ExportCSV extends LightningElement {
    @api sObjectName;
    @api fieldNames = [];
    @api conditions;
    @api orderBy = null;
    @api reportType;
    @api downloadFileName;
    @api downloadfilename;
    @api ppeValue;
    @api ppevalue;
    loading = false;
    dataToDownload = [];
    nextRecordsUrl = "";
    fieldMap = [];
    apiNames = [];
    columnLables = [];

    connectedCallback() {
        getFieldMap({ reportType: this.reportType }).then(res => {

            this.loading = true;
            //let columnLables = [];
            if(res.labels && res.apinames){
                this.columnLables = res.labels;
                this.apiNames = res.apinames;
            }
            /*
            res.forEach(field => {
                this.apiNames.push(field.apiname);
                this.columnLables.push(field.label);
            });*/
            this.exportData();

        }).catch(e => {
            console.error(e);
        });
    }

    exportData() {
        let fun = null;
        if (this.nextRecordsUrl) {
            fun = fetchNext({ 'url': this.nextRecordsUrl.replace('/services/data/v58.0/query', '') });
        } else {
            if (this.sObjectName == 'DHS_Case__c') this.orderBy = "Case_Queue_Status__c desc";
            if (this.sObjectName == 'DIA_Lead__c') this.orderBy = "Status__c desc";
            if (this.sObjectName == 'DHS_Case__c') this.orderBy = "CreatedDate asc";
            console.log(this.conditions);
            let payload = { sObjectName: this.sObjectName, fieldNames: this.apiNames, conditions: this.conditions, querylimit: null, orderBy: this.orderBy };
            fun = tooling(payload)
        }
        console.log("@@@@", this.sObjectName);
        fun.then(res => {
            res = JSON.parse(res);
            if (!res.records) {
                this.loading = false;
            } else {
                this.dataToDownload = this.dataToDownload.concat(res.records);
                if (res.nextRecordsUrl) {
                    this.nextRecordsUrl = res.nextRecordsUrl;
                    this.exportData();
                    // this.exportCSV(columnLables, this.dataToDownload, 'data');
                    // this.loading = false;
                } else {
                    this.exportCSV(this.columnLables, this.dataToDownload, this.getDownloadFileName());
                    this.loading = false;
                }
            }
        }).catch(error => { console.error(error) });
    }

    getDownloadFileName() {
        if (this.downloadFileName) {
            return this.downloadFileName;
        }
        if (this.downloadfilename) {
            return this.downloadfilename;
        }
        if (this.reportType === 'invoice') {
            const startDate = this.getConditionValue('Date__c', '>=');
            const endDate = this.getConditionValue('Date__c', '<=');
            const ppeDate = this.getPpeValue() || endDate || startDate;
            return `Invoices_PPE_${this.formatDateForFileName(ppeDate)}`;
        }
        return 'data';
    }

    getPpeValue() {
        return this.ppeValue || this.ppevalue || '';
    }

    getConditionValue(key, operator) {
        const condition = (this.conditions || []).find(item => item.key === key && item.operator === operator);
        return condition ? condition.value : '';
    }

    formatDateForFileName(dateValue) {
        if (!dateValue) {
            return '';
        }
        if (dateValue.includes('/')) {
            const parts = dateValue.split('/');
            return `${parts[0].padStart(2, '0')}-${parts[1].padStart(2, '0')}-${parts[2]}`;
        }
        const parts = dateValue.split('-');
        return `${parts[1]}-${parts[2]}-${parts[0]}`;
    }

    exportCSV(headers, totalData, fileTitle) {
        if (!totalData || !totalData.length) {
            return null
        }
        const jsonObject = JSON.stringify(totalData);
        const result = this.convertToCSV(jsonObject, headers);
        if (result === null) return
        const blob = new Blob([result]);
        if (this.reportType === 'invoice' && (!fileTitle || fileTitle === 'data')) {
            fileTitle = this.getDownloadFileName();
        }
        const exportedFilename = fileTitle ? fileTitle + '.csv' : 'DashBoardChartExport.csv'
        //const exportedFilename = 'DashBoardChartExport '+fileTitle ? fileTitle : 'DashBoardChartExport';

        if (navigator.msSaveBlob) {
            navigator.msSaveBlob(blob, exportedFilename)
        } else if (navigator.userAgent.match(/iPhone|iPad|iPod/i)) {
            const link = window.document.createElement('a')
            link.href = 'data:text/csv;charset=utf-8,' + encodeURI(result);
            link.target = "_blank"
            link.download = exportedFilename
            link.click()
        } else {
            const link = document.createElement("a")
            if (link.download !== undefined) {
                const url = URL.createObjectURL(blob);
                link.setAttribute("href", url);
                link.setAttribute("download", exportedFilename);
                link.style.visibility = 'hidden';
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
            }
        }


    }

    convertToCSV(objArray, headers) {
        headers = JSON.parse(JSON.stringify(headers));
        const ppeValue = this.getPpeValue();
        let apiNames = this.apiNames;
        let ppeHeaderIndex = -1;
        if (this.reportType === 'invoice' && ppeValue) {
            ppeHeaderIndex = headers.findIndex(header => {
                const headerValue = header.name || header;
                return headerValue === 'PPE';
            });
            if (ppeHeaderIndex === -1) {
                headers.push('PPE');
                apiNames = apiNames.concat(['PPE']);
            }
        }
        const columnDelimiter = ',';
        const lineDelimiter = '\r\n';
        let str = '';

        headers.forEach(currentItem => {
            if (currentItem.name) {
                str += currentItem.name.replace(/,/g, '') + ',';
            } else {
                str += currentItem.replace(/,/g, '') + ',';
            }
        });
        str = str.slice(0, -1);
        str += lineDelimiter;
        const data = typeof objArray !== 'object' ? JSON.parse(objArray) : objArray;

        const flatten = (obj, roots = [], sep = '.') => Object
            // find props of given object
            .keys(obj)
            // return an object by iterating props
            .reduce((memo, prop) => Object.assign(
                // create a new object
                {},
                // include previously returned object
                memo,
                Object.prototype.toString.call(obj[prop]) === '[object Object]'
                    // keep working if value is an object
                    ? flatten(obj[prop], roots.concat([prop]), sep)
                    // include current prop and value and prefix prop with the roots
                    : { [roots.concat([prop]).join(sep)]: obj[prop] }
            ), {})

        let flattendata = [];
        data.forEach(obj => {
            flattendata.push(flatten(obj));
        });
        flattendata.forEach(obj => {
            let line = '';

            apiNames.forEach((key, index) => {
                if (index > 0) {
                    line += columnDelimiter;
                }

                let apiName = key.apiname || key;
                let strItem = (obj[apiName] || '') + '';

                if (this.reportType === 'invoice' && ppeValue && (apiName === 'Pay_Period_Ending__c' || apiName === 'PPE' || index === ppeHeaderIndex)) {
                    strItem = ppeValue;
                }

                if (strItem?.includes(";")) {
                    strItem = strItem.replaceAll(";", '*');
                }
                if (strItem?.includes(",")) {
                    strItem = strItem.replaceAll(",", ' ');
                }

                // Handle extra new line values
                strItem = strItem !== undefined && strItem !== null ? strItem.replace(/\n/g, ' ') : '';

                // Handle \r values
                strItem = strItem !== undefined && strItem !== null ? strItem.replace(/\r/g, ' ') : '';

                // Handle empty values
                line += strItem !== undefined && strItem !== null ? strItem.replace(/,/g, '') : '';

            });
            str += line + lineDelimiter;
        });
        return str;
    }
}