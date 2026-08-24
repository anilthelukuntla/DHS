import { LightningElement, wire, track } from "lwc";
import { gql, graphql } from "lightning/uiGraphQLApi";
import Id from '@salesforce/user/Id';
export default class DisplayCaseContacts extends LightningElement {
    results;
    errors;
    userId = Id;
    @track data = [];
    @track columns = [
        { label: 'Name', fieldName: 'name' },
        { label: 'Case Name', fieldName: 'caseName' },
        { label: 'Contact Name', fieldName: 'contactName' }
    ];

    get queryData() {
        return {
            userId: this.userId
        };
        
    }

    @wire(graphql, {
        query: gql`
      query DIALeads ($userId: ID!) {
        uiapi {
        query {
            DIA_Lead__c (where: { DHS_Assigned_To__c: { eq: $userId } }){
                edges {
                    node {
                        Id
                        DHS_Case__r {
                            Id
                            Name {
                                value
                            }
                            DHS_Contact__r {
                                Name {
                                    value
                                }
                            }
                        }
                    }
                }
            
            }
        }
    }
      }
    `,
        variables: "$queryData",
    })
    graphqlQueryResult({ data, errors }) {
        console.log(this.userId);
        if (data) {
            let results = data.uiapi.query.DIA_Lead__c.edges.map((edge) => edge.node);
            if (results?.length) {
                this.data = [];
                results.forEach(currentItem => {
                    this.data.push({
                        id: currentItem.Id,
                        name: currentItem.Id,
                        caseName: currentItem.DHS_Case__r.Name.value,
                        contactName: currentItem.DHS_Case__r.DHS_Contact__r.Name.value
                    });
                });
            }
        }
        this.errors = errors;
    }
}

/**
 * query {
    uiapi {
        query {
            DHS_Case__c {
                edges {
                    node {
                        Id
                        Name {
                            value
                        }
                        DHS_Contact__r {
                            Name {
                                value
                            }
                        }
                    }
                }
            }
        }
    }
}
 */