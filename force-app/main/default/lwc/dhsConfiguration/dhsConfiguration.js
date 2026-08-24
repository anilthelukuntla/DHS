import { LightningElement, wire, api } from "lwc";
import getReportExport from "@salesforce/apex/DHSUtils.getReportExport";
import saveReport from "@salesforce/apex/DHSUtils.saveReport";
export default class Configuration extends LightningElement {
    value = '';
    userMap;
    dragMap;
    reportData = [];
    reloadAttributes = false;
    

    get options() {
        return [
            { label: 'choose one...', value: '' },
            { label: 'Case', value: 'Case' },
            { label: 'Lead', value: 'Lead' },
            { label: 'Check-in/Out', value: 'Check-in/Out' },
            { label: 'Message', value: 'Message' },
            { label: 'Waiver', value: 'Waiver' },
        ];
    }
    handleChange(event) {
        this.value = event.detail.value;
        /*
        this.reloadAttributes = true;
        
        getReportExport({reportType:this.value,currentSystem:'Intel'}).then(res=>{
            if (!!this.res) {
                this.reloadAttributes = false;
                this.userMap = new Map();
                let tempArray = JSON.parse(JSON.stringify(this.res));
                tempArray.forEach((arrayElement, index) => {
                    arrayElement.index = index;
                    this.userMap.set(arrayElement.Id, arrayElement);
                });
                this.res = JSON.parse(JSON.stringify(tempArray));  
                this.reportData = this.res;  
            }
        }).catch(e=>{
            console.error(e);
        });*/
    }
    findData(){
        console.log(this.value);
        getReportExport({reportType:this.value,currentSystem:'Intel'}).then(res=>{
            if(res){
                console.log(this.reportData);
                this.reloadAttributes = false;
                this.userMap = new Map();
                let tempArray = JSON.parse(JSON.stringify(res));
                tempArray.forEach((arrayElement, index) => {
                    arrayElement.index = index;
                    this.userMap.set(arrayElement.Id, arrayElement);
                });
                this.reportData = [...tempArray];
                /*res = JSON.parse(JSON.stringify(tempArray));  
                this.reportData = res;  */
            }
        }).catch(e=>{
            console.error(e);
        })
    }
    
  handleSubmit() {
    console.log("in submit method");
    let sortedData = this.reportData.sort((a, b) => a.index - b.index);
    let mappedData = this.transposeData(sortedData);
    saveReport({revisedData:mappedData}).then(res=>{
        
    }).catch(e=>{console.error(e)});
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

        Array.from(this.dragMap).reverse().forEach( element => {
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

}