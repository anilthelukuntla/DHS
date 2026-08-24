/**
 * @description Retains the existing DHSMockHttpResponseGenerator integration and application behavior.
 */

public class DHSMockHttpResponseGenerator implements HttpCalloutMock {
        private String responseBody;
        
        /**
         * @description Provides this DHS API member.
         * @param response Method parameter.
         */
        public DHSMockHttpResponseGenerator(String response) {
            responseBody = response;
        }

        /**
         * @description Provides this DHS API member.
         * @param req Method parameter.
         * @return The requested result.
         */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(responseBody);
            response.setStatusCode(200);
            return response;
        }
    }
