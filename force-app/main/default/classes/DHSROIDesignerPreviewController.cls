/**
 * @description Prepares rendered DHS ROI designer output for Visualforce preview.
 */
@SuppressWarnings('PMD.NcssConstructorCount')
public with sharing class DHSROIDesignerPreviewController {
    /**
     * @description Rendered report markup.
     */
    public String renderedHtml { get; private set; }
    /**
     * @description Customer-facing case number displayed by the preview.
     */
    public String customerCaseNumber { get; private set; }

    /**
     * @description Validates page identifiers and renders the selected case preview.
     */
    public DHSROIDesignerPreviewController() {
        Id caseId;
        Id sequenceId;
        String idParam = ApexPages.currentPage().getParameters().get('id');
        if (String.isNotBlank(idParam)) {
            try {
                caseId = Id.valueOf(idParam);
            } catch (Exception ex) {
                caseId = null;
            }
        }
        String sequenceParam = ApexPages.currentPage().getParameters().get('sequenceid');
        if (String.isNotBlank(sequenceParam)) {
            try {
                sequenceId = Id.valueOf(sequenceParam);
            } catch (Exception ex) {
                sequenceId = null;
            }
        }
        customerCaseNumber = '';
        if (caseId != null) {
            List<DHS_Case__c> cases = [
                SELECT Customer_Case_Number__c
                FROM DHS_Case__c
                WHERE Id = :caseId
                 WITH USER_MODE LIMIT 1
            ];
            if (!cases.isEmpty()) {
                customerCaseNumber = cases[0].Customer_Case_Number__c;
            }
        }
        renderedHtml = DHSROIDesignerController.renderCasePreview(caseId, sequenceId);
    }
}