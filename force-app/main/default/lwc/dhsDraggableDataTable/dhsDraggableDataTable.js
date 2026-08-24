import { LightningElement, wire, api, track } from "lwc";
import getUsers from "@salesforce/apex/DHSUtils.getReportExport";
import saveReport from "@salesforce/apex/DHSUtils.saveReport";
import LightningConfirm from 'lightning/confirm';
import { deleteRecord } from 'lightning/uiRecordApi';
export default class DraggableDataTable extends LightningElement {
  @track rowData = {};
  @api currentsystem = 'Intel';
  userMap;
  dragMap;
  reportData = [];
  value = '';
  @track isEdit = false;
  showDataTable = false;
  showUpsertReportExport = false;
  @track unableButtons = true;
  get options() {
    if (this.currentsystem === 'Intel') {
      return [
        { label: 'choose one...', value: '' },
        { label: 'ROIReport', value: 'Document__c' },
        { label: 'Case', value: 'Case__c' },
        { label: 'Lead', value: 'Lead__c' },
        { label: 'Check-in/Check-out', value: 'Investigator_Check__c' },
        { label: 'Messages', value: 'Message__c' },
        { label: 'Waivers', value: 'Waiver_Information__c' }
      ];
    } else if (this.currentsystem === 'BI') {
      return [
        { label: 'choose one...', value: '' },
        { label: 'ROIReport', value: 'DIA_Document__c' },
        { label: 'Case', value: 'Case__c' },
        { label: 'Lead', value: 'DIA_Lead__c' },
        { label: 'Check-in/Check-out', value: 'DIA_Investigator_Check__c' },
        { label: 'Messages', value: 'DIA_Message__c' },
        { label: 'Waivers', value: 'DIA_Waiver_Information__c' }
      ];
    }
  }
  handleChange(event) {
    this.value = event.detail.value;
    if (this.value != '') {
      this.showDataTable = true;
      this.unableButtons = false;
      this.fetchRecords();
    } else {
      this.unableButtons = true;
      this.showDataTable = false;
    }
  }
  fetchRecords() {
    this.showDataTable = false;
    getUsers({ reportType: this.value, currentSystem: this.currentsystem }).then(res => {
      if (res) {
        this.showDataTable = true;
        console.log(res);
        this.reportData = res;
        this.userMap = new Map();
        let tempArray = JSON.parse(JSON.stringify(this.reportData));
        console.log(tempArray);
        tempArray.forEach((arrayElement, index) => {
          arrayElement.index = index;
          this.userMap.set(arrayElement.Id, arrayElement);
        });
        this.reportData = JSON.parse(JSON.stringify(tempArray));
      }
    }

    ).catch(e => {
      console.error(e);
    });
  }
  async handleSubmit() {
    console.log("in submit method");
    console.log(this.reportData);
    let sortedData = this.reportData.sort((a, b) => a.index - b.index);
    console.log(sortedData);
    let mappedData = this.transposeData(sortedData);

    const result = await LightningConfirm.open({
      message: 'Are you sure you want to save the column order?',
      label: 'Update Confirmation', // Header text
      theme: 'warning', // Theme for the modal: 'default', 'success', 'warning', 'error'
    });
    if (result) {
      saveReport({ revisedData: mappedData }).then(res => {
        this.fetchRecords();
      }).catch(e => { console.error(e) });
    }
  }

  processRowNumbers() {

    const trs = this.template.querySelectorAll(".myIndex");
    const ids = this.template.querySelectorAll(".myId");
    for (let i = 0; i < trs.length; i++) {
      let currentRowId = ids[i].innerText;
      let currentRowRef = this.userMap.get(currentRowId);
      currentRowRef.index = i;
      this.userMap.set(currentRowId, currentRowRef);
      trs[i].innerText = i;
    }
    this.reportData = Array.from(this.userMap.values());
  }

  onDragStart(evt) {
    const inputs = this.template.querySelectorAll(".mychkbox");
    this.dragMap = new Map();

    if (inputs) {
      for (let i = 0; i < inputs.length; i++) {
        if (inputs[i].checked) {
          let currentRow = inputs[i].parentNode.parentNode;
          let currentDragId = currentRow.dataset.dragId;
          this.dragMap.set(currentDragId, currentRow);
          //currentRow.classList.add("grabbed");
        }
      }
    }

    let eventRowDataId = evt.currentTarget.dataset.dragId;
    evt.dataTransfer.setData("dragId", eventRowDataId);
    evt.dataTransfer.setData("sy", evt.pageY);
    evt.dataTransfer.effectAllowed = "move";
    evt.currentTarget.classList.add("grabbed");

    if (this.dragMap.has(eventRowDataId)) {
      this.dragMap.forEach((value) => value.classList.add("grabbed"));
    }
  }

  onDragOver(evt) {
    evt.preventDefault();
    evt.dataTransfer.dropEffect = "move";
  }

  onDrop(evt) {
    evt.preventDefault();
    let sourceId = evt.dataTransfer.getData("dragId");

    const sy = evt.dataTransfer.getData("sy");
    const cy = evt.pageY;

    if (sy > cy) {
      if (this.dragMap.has(sourceId)) {

        Array.from(this.dragMap).reverse().forEach(element => {
          let key = element[0];
          const elm = this.template.querySelector(`[data-drag-id="${key}"]`);
          if (!!elm) {
            elm.classList.remove("grabbed");
          }
          evt.currentTarget.parentElement.insertBefore(elm, evt.currentTarget);
        });
      } else {
        const elm = this.template.querySelector(`[data-drag-id="${sourceId}"]`);
        if (!!elm) {
          elm.classList.remove("grabbed");
        }
        evt.currentTarget.parentElement.insertBefore(elm, evt.currentTarget);
      }
    } else {
      if (this.dragMap.has(sourceId)) {
        this.dragMap.forEach((value, key, map) => {
          const elm = this.template.querySelector(`[data-drag-id="${key}"]`);
          if (!!elm) {
            elm.classList.remove("grabbed");
          }
          evt.currentTarget.parentElement.insertBefore(
            elm,
            evt.currentTarget.nextElementSibling
          );
        });
      } else {
        const elm = this.template.querySelector(`[data-drag-id="${sourceId}"]`);
        if (!!elm) {
          elm.classList.remove("grabbed");
        }
        evt.currentTarget.parentElement.insertBefore(
          elm,
          evt.currentTarget.nextElementSibling
        );
      }
    }
    this.processRowNumbers();
  }
  transposeData(data) {
    return data.reduce((result, item) => {
      result[item.Id] = item.index;
      return result;
    }, {});
  }
  handleClick(evt) {
    const id = evt.currentTarget.dataset.id;
    const label = evt.currentTarget.dataset.label;
    const apiname = evt.currentTarget.dataset.apiname;
    const index = evt.currentTarget.dataset.index;
    let data = {};
    data.id = id;
    data.apiname = apiname;
    data.label = label;
    data.index = index;
    this.rowData = data;
    this.showUpsertReportExport = true;
    this.isEdit = true;
  }
  async handleDelete(e) {
    const id = e.currentTarget.dataset.id;
    const result = await LightningConfirm.open({
      message: 'Are you sure you want to delete?',
      label: 'Delete Confirmation', // Header text
      theme: 'warning', // Theme for the modal: 'default', 'success', 'warning', 'error'
    });
    if (result) {
      deleteRecord(id).then(() => {
        this.fetchRecords();
      }).catch(error => { console.error(error) });
    }
  }
  handleCloseEvt() {
    this.showUpsertReportExport = false;
    this.fetchRecords();
  }
  handleSaveField() {
    this.showUpsertReportExport = false;
    this.fetchRecords();
    //need to refresh the datatable
  }
  handleAddColumn() {
    this.showUpsertReportExport = true;
    this.rowData = {};
    this.isEdit = false;
  }
}