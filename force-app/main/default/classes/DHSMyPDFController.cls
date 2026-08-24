/**
 * @description Configures the DHS custom report page as a PDF download.
 */
public class DHSMyPDFController {
    /**
     * @description Sets the response content-disposition filename.
     */
    public DHSMyPDFController() {
        ApexPages.currentPage().getHeaders().put(
            'Content-Disposition',
            'attachment; filename=CustomReport.pdf'
        );
    }
}
