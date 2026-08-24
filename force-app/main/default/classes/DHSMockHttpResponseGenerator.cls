/** Retains the existing DHSMockHttpResponseGenerator integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc')
public class DHSMockHttpResponseGenerator implements HttpCalloutMock {
        private String responseBody;
        
        public DHSMockHttpResponseGenerator(String response) {
            responseBody = response;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(responseBody);
            response.setStatusCode(200);
            return response;
        }
    }
