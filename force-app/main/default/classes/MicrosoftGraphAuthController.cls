/** Validates Microsoft Graph delegated and application authentication. */
@SuppressWarnings('PMD.ApexDoc, PMD.EmptyStatementBlock, PMD.EmptyCatchBlock, PMD.EmptyIfStmt')
public with sharing class MicrosoftGraphAuthController {

    private static final String GRAPH_CALLOUT_NAME = 'MicrosoftGraph';
    private static final String GRAPH_API_VERSION = 'v2.0';
    private static final Integer CALLOUT_TIMEOUT = 120000;

    /**
     * Validates delegated authentication.
     *
     * Uses the currently authenticated Microsoft user's profile.
     * Requires Microsoft Graph delegated permission: User.Read
     */
    @AuraEnabled
    public static AuthenticationResult validateDelegatedAuthentication() {
        return validateEndpoint('/me?$select=id,displayName,userPrincipalName,mail');
    }

    /**
     * Validates application/client-credentials authentication.
     *
     * The /me endpoint cannot be used with application permissions,
     * so a Microsoft user ID or user principal name is required.
     *
     * Requires Microsoft Graph application permission:
     * User.Read.All
     */
    @AuraEnabled
    public static AuthenticationResult validateApplicationAuthentication(
        String userIdentifier
    ) {
        if (String.isBlank(userIdentifier)) {
            throw new AuraHandledException(
                'Microsoft user ID or user principal name is required.'
            );
        }

        String encodedUserIdentifier = EncodingUtil.urlEncode(
            userIdentifier.trim(),
            'UTF-8'
        );

        String resource =
            '/users/' +
            encodedUserIdentifier +
            '?$select=id,displayName,userPrincipalName,mail';

        return validateEndpoint(resource);
    }

    /**
     * Server-side method that can be called from other Apex classes.
     */
    public static AuthenticationResult validateEndpoint(String resource) {
        AuthenticationResult result = new AuthenticationResult();
        result.authenticated = false;

        try {
            HttpResponse response = sendRequest(resource);

            if (response.getStatusCode() == 200) {
                GraphUser graphUser = (GraphUser) JSON.deserialize(
                    response.getBody(),
                    GraphUser.class
                );

                result.authenticated = true;
                result.statusCode = response.getStatusCode();
                result.message =
                    'Microsoft Graph authentication was successful.';

                if (graphUser != null) {
                    result.microsoftUserId = graphUser.id;
                    result.displayName = graphUser.displayName;
                    result.userPrincipalName =
                        graphUser.userPrincipalName;
                    result.email = graphUser.mail;
                }

                return result;
            }

            return buildFailureResult(response);
        } catch (CalloutException calloutException) {
            result.statusCode = 0;
            result.message =
                'Unable to connect to Microsoft Graph: ' +
                calloutException.getMessage();

            return result;
        } catch (Exception unexpectedException) {
            result.statusCode = 0;
            result.message =
                'Microsoft Graph authentication validation failed: ' +
                unexpectedException.getMessage();

            return result;
        }
    }

    private static HttpResponse sendRequest(String resource) {
        if (String.isBlank(resource) || !resource.startsWith('/')) {
            throw new MicrosoftGraphAuthException(
                'A valid Microsoft Graph resource path is required.'
            );
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(
            'callout:' +
            GRAPH_CALLOUT_NAME +
            '/' +
            GRAPH_API_VERSION +
            resource
        );
        request.setHeader('Accept', 'application/json');
        request.setTimeout(CALLOUT_TIMEOUT);

        /*
         * Do not manually add the Authorization header.
         * The Named Credential adds and refreshes the OAuth token.
         */
        return new Http().send(request);
    }

    private static AuthenticationResult buildFailureResult(
        HttpResponse response
    ) {
        AuthenticationResult result = new AuthenticationResult();
        result.authenticated = false;
        result.statusCode = response.getStatusCode();
        result.message = getGraphErrorMessage(response);

        if (response.getStatusCode() == 401) {
            result.message =
                'Microsoft Graph authentication failed. ' +
                result.message;
        } else if (response.getStatusCode() == 403) {
            result.message =
                'Microsoft Graph authentication succeeded, but the ' +
                'application does not have the required permission. ' +
                result.message;
        } else if (response.getStatusCode() == 404) {
            result.message =
                'Authentication succeeded, but the requested Microsoft ' +
                'user was not found.';
        }

        return result;
    }

    private static String getGraphErrorMessage(HttpResponse response) {
        String defaultMessage =
            'Microsoft Graph returned HTTP ' +
            response.getStatusCode() +
            ' ' +
            response.getStatus() +
            '.';

        if (String.isBlank(response.getBody())) {
            return defaultMessage;
        }

        try {
            GraphErrorResponse errorResponse =
                (GraphErrorResponse) JSON.deserialize(
                    response.getBody(),
                    GraphErrorResponse.class
                );

            if (
                errorResponse != null &&
                errorResponse.error != null &&
                String.isNotBlank(errorResponse.error.message)
            ) {
                return String.isBlank(errorResponse.error.code)
                    ? errorResponse.error.message
                    : errorResponse.error.code +
                        ': ' +
                        errorResponse.error.message;
            }
        } catch (JSONException ignoredException) {
            // Return the generic error without exposing the response body.
        }

        return defaultMessage;
    }

    public class AuthenticationResult {

        @AuraEnabled
        public Boolean authenticated { get; private set; }

        @AuraEnabled
        public Integer statusCode { get; set; }

        @AuraEnabled
        public String message { get; set; }

        @AuraEnabled
        public String microsoftUserId { get; set; }

        @AuraEnabled
        public String displayName { get; set; }

        @AuraEnabled
        public String userPrincipalName { get; set; }

        @AuraEnabled
        public String email { get; set; }
    }

    private class GraphUser {
        public String id;
        public String displayName;
        public String userPrincipalName;
        public String mail;
    }

    private class GraphErrorResponse {
        public GraphError error;
    }

    private class GraphError {
        public String code;
        public String message;
    }

    public class MicrosoftGraphAuthException extends Exception {
    }
}