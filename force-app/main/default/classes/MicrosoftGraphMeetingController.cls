/**
 * Finds Microsoft Graph meeting-time suggestions and exposes the response
 * models required by the existing UI integration.
 */
@SuppressWarnings('PMD.ApexDoc, PMD.ExcessiveParameterList, PMD.CyclomaticComplexity, PMD.EmptyStatementBlock, PMD.EmptyCatchBlock, PMD.EmptyIfStmt')
public with sharing class MicrosoftGraphMeetingController {

    private static final String GRAPH_CALLOUT_NAME = 'MicrosoftGraph';
    private static final String GRAPH_API_VERSION = 'v1.0';
    private static final Integer CALLOUT_TIMEOUT = 120000;
    private static final Integer DEFAULT_MAX_CANDIDATES = 20;

    /**
     * Finds suitable meeting times using organizer and attendee email addresses.
     *
     * Required delegated Microsoft Graph permissions:
     * - User.ReadBasic.All or User.Read.All
     * - Calendars.Read.Shared
     *
     * Example date/time:
     * 2026-07-24T09:00:00
     *
     * Example Microsoft time zone:
     * Eastern Standard Time
     */
    @AuraEnabled
    public static MeetingTimesResult findMeetingTimes(
        String organizerEmail,
        List<String> attendeeEmails,
        String startDateTime,
        String endDateTime,
        String timeZone,
        Integer durationMinutes
    ) {
        validateInputs(
            organizerEmail,
            attendeeEmails,
            startDateTime,
            endDateTime,
            timeZone,
            durationMinutes
        );

        try {
            String normalizedOrganizerEmail = organizerEmail.trim();

            String organizerUserId = findUserIdByEmail(
                normalizedOrganizerEmail
            );

            if (String.isBlank(organizerUserId)) {
                return buildFailure(
                    404,
                    'No Microsoft user was found with organizer email: ' +
                    normalizedOrganizerEmail
                );
            }

            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint(
                buildEndpoint(
                    '/users/' +
                    EncodingUtil.urlEncode(organizerUserId, 'UTF-8') +
                    '/findMeetingTimes'
                )
            );
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader(
                'Prefer',
                'outlook.timezone="' +
                sanitizeHeaderValue(timeZone) +
                '"'
            );
            request.setTimeout(CALLOUT_TIMEOUT);
            request.setBody(
                buildRequestBody(
                    attendeeEmails,
                    startDateTime,
                    endDateTime,
                    timeZone,
                    durationMinutes
                )
            );

            HttpResponse response = new Http().send(request);

            if (response.getStatusCode() != 200) {
                return buildGraphFailure(response);
            }

            return buildSuccessResult(
                response,
                normalizedOrganizerEmail,
                organizerUserId
            );
        } catch (CalloutException ex) {
            return buildFailure(
                0,
                'Unable to connect to Microsoft Graph: ' +
                ex.getMessage()
            );
        } catch (MicrosoftGraphMeetingException ex) {
            return buildFailure(
                0,
                ex.getMessage()
            );
        } catch (Exception ex) {
            return buildFailure(
                0,
                'Unable to find meeting times: ' +
                ex.getMessage()
            );
        }
    }

    /**
     * Resolves a Microsoft user's email address to their Entra user ID.
     *
     * It checks both:
     * - mail
     * - userPrincipalName
     */
    private static String findUserIdByEmail(String email) {
        String escapedEmail = escapeODataString(email);

        String filter =
            'mail eq \'' +
            escapedEmail +
            '\' or userPrincipalName eq \'' +
            escapedEmail +
            '\'';

        String resource =
            '/users' +
            '?$filter=' +
            EncodingUtil.urlEncode(filter, 'UTF-8') +
            '&$select=id,displayName,mail,userPrincipalName' +
            '&$top=2';

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(buildEndpoint(resource));
        request.setHeader('Accept', 'application/json');
        request.setTimeout(CALLOUT_TIMEOUT);
        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() != 200) {
            throw new MicrosoftGraphMeetingException(
                'Unable to find Microsoft user: ' +
                getGraphErrorMessage(response)
            );
        }

        GraphUsersResponse usersResponse =
            (GraphUsersResponse) JSON.deserialize(
                response.getBody(),
                GraphUsersResponse.class
            );

        if (
            usersResponse == null ||
            usersResponse.value == null ||
            usersResponse.value.isEmpty()
        ) {
            return null;
        }

        if (usersResponse.value.size() > 1) {
            throw new MicrosoftGraphMeetingException(
                'Multiple Microsoft users were found for email: ' +
                email
            );
        }

        return usersResponse.value[0].id;
    }

    private static MeetingTimesResult buildSuccessResult(
        HttpResponse response,
        String organizerEmail,
        String organizerUserId
    ) {
        MeetingTimesResult result = new MeetingTimesResult();
        result.success = true;
        result.statusCode = response.getStatusCode();
        result.message = 'Meeting times retrieved successfully.';
        result.organizerEmail = organizerEmail;
        result.organizerMicrosoftUserId = organizerUserId;
        result.responseBody = response.getBody();

        /*
         * dateTime is a reserved Apex identifier.
         *
         * Replace the Graph JSON property name before deserializing it
         * into the Apex dateTimeValue property.
         */
        String responseBodyForParsing = response
            .getBody()
            .replace('"dateTime"', '"dateTimeValue"');

        MeetingSuggestionsResponse suggestions =
            (MeetingSuggestionsResponse) JSON.deserialize(
                responseBodyForParsing,
                MeetingSuggestionsResponse.class
            );

        if (suggestions == null) {
            result.meetingTimeSuggestions =
                new List<MeetingTimeSuggestion>();

            return result;
        }

        result.emptySuggestionsReason =
            suggestions.emptySuggestionsReason;

        result.meetingTimeSuggestions =
            suggestions.meetingTimeSuggestions == null
                ? new List<MeetingTimeSuggestion>()
                : suggestions.meetingTimeSuggestions;

        return result;
    }

    private static String buildRequestBody(
        List<String> attendeeEmails,
        String startDateTime,
        String endDateTime,
        String timeZone,
        Integer durationMinutes
    ) {
        List<Object> attendees = buildAttendees(attendeeEmails);

        Map<String, Object> startValue =
            new Map<String, Object>{
                'dateTime' => startDateTime.trim(),
                'timeZone' => timeZone.trim()
            };

        Map<String, Object> endValue =
            new Map<String, Object>{
                'dateTime' => endDateTime.trim(),
                'timeZone' => timeZone.trim()
            };

        Map<String, Object> timeSlot =
            new Map<String, Object>{
                'start' => startValue,
                'end' => endValue
            };

        Map<String, Object> timeConstraint =
            new Map<String, Object>{
                'activityDomain' => 'work',
                'timeSlots' => new List<Object>{ timeSlot }
            };

        Map<String, Object> requestBody =
            new Map<String, Object>{
                'attendees' => attendees,
                'timeConstraint' => timeConstraint,
                'meetingDuration' =>
                    'PT' + durationMinutes + 'M',
                'returnSuggestionReasons' => true,
                'minimumAttendeePercentage' => 100,
                'maxCandidates' => DEFAULT_MAX_CANDIDATES,
                'isOrganizerOptional' => false
            };

        return JSON.serialize(requestBody);
    }

    private static List<Object> buildAttendees(
        List<String> attendeeEmails
    ) {
        List<Object> attendees = new List<Object>();
        Set<String> processedEmails = new Set<String>();

        for (String attendeeEmail : attendeeEmails) {
            if (String.isBlank(attendeeEmail)) {
                continue;
            }

            String trimmedEmail = attendeeEmail.trim();
            String normalizedEmail = trimmedEmail.toLowerCase();

            if (processedEmails.contains(normalizedEmail)) {
                continue;
            }

            processedEmails.add(normalizedEmail);

            attendees.add(
                new Map<String, Object>{
                    'type' => 'required',
                    'emailAddress' => new Map<String, Object>{
                        'address' => trimmedEmail
                    }
                }
            );
        }

        if (attendees.isEmpty()) {
            throw new AuraHandledException(
                'At least one valid attendee email is required.'
            );
        }

        return attendees;
    }

    private static void validateInputs(
        String organizerEmail,
        List<String> attendeeEmails,
        String startDateTime,
        String endDateTime,
        String timeZone,
        Integer durationMinutes
    ) {
        if (String.isBlank(organizerEmail)) {
            throw new AuraHandledException(
                'Organizer email is required.'
            );
        }

        if (attendeeEmails == null || attendeeEmails.isEmpty()) {
            throw new AuraHandledException(
                'At least one attendee email is required.'
            );
        }

        if (String.isBlank(startDateTime)) {
            throw new AuraHandledException(
                'Start date and time are required.'
            );
        }

        if (String.isBlank(endDateTime)) {
            throw new AuraHandledException(
                'End date and time are required.'
            );
        }

        if (String.isBlank(timeZone)) {
            throw new AuraHandledException(
                'Microsoft time zone is required.'
            );
        }

        if (durationMinutes == null || durationMinutes <= 0) {
            throw new AuraHandledException(
                'Meeting duration must be greater than zero.'
            );
        }
    }

    private static String buildEndpoint(String resource) {
        return 'callout:' +
            GRAPH_CALLOUT_NAME +
            '/' +
            GRAPH_API_VERSION +
            resource;
    }

    private static String escapeODataString(String value) {
        return value.replace('\'', '\'\'');
    }

    private static String sanitizeHeaderValue(String value) {
        return value
            .trim()
            .replace('"', '')
            .replace('\r', '')
            .replace('\n', '');
    }

    private static MeetingTimesResult buildGraphFailure(
        HttpResponse response
    ) {
        String message = getGraphErrorMessage(response);

        if (response.getStatusCode() == 401) {
            message =
                'Microsoft Graph authentication failed. ' +
                message;
        } else if (response.getStatusCode() == 403) {
            message =
                'Authentication succeeded, but the authenticated ' +
                'Microsoft user or application does not have the ' +
                'required calendar permission. ' +
                message;
        } else if (response.getStatusCode() == 404) {
            message =
                'The Microsoft user or findMeetingTimes resource ' +
                'was not found. ' +
                message;
        }

        return buildFailure(
            response.getStatusCode(),
            message
        );
    }

    private static MeetingTimesResult buildFailure(
        Integer statusCode,
        String message
    ) {
        MeetingTimesResult result = new MeetingTimesResult();
        result.success = false;
        result.statusCode = statusCode;
        result.message = message;
        result.meetingTimeSuggestions =
            new List<MeetingTimeSuggestion>();

        return result;
    }

    private static String getGraphErrorMessage(
        HttpResponse response
    ) {
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
                if (String.isBlank(errorResponse.error.code)) {
                    return errorResponse.error.message;
                }

                return errorResponse.error.code +
                    ': ' +
                    errorResponse.error.message;
            }
        } catch (JSONException ignoredException) {
        }

        return defaultMessage;
    }

    public class MeetingTimesResult {

        @AuraEnabled
        public Boolean success { get; private set; }

        @AuraEnabled
        public Integer statusCode { get; set; }

        @AuraEnabled
        public String message { get; set; }

        @AuraEnabled
        public String organizerEmail { get; set; }

        @AuraEnabled
        public String organizerMicrosoftUserId { get; set; }

        @AuraEnabled
        public String emptySuggestionsReason { get; set; }

        @AuraEnabled
        public String responseBody { get; set; }

        @AuraEnabled
        public List<MeetingTimeSuggestion> meetingTimeSuggestions {
            get;
            set;
        }
    }

    private class MeetingSuggestionsResponse {
        public String emptySuggestionsReason;
        public List<MeetingTimeSuggestion> meetingTimeSuggestions;
    }

    public class MeetingTimeSuggestion {

        @AuraEnabled
        public Decimal confidence { get; set; }

        @AuraEnabled
        public String suggestionReason { get; set; }

        @AuraEnabled
        public String organizerAvailability { get; set; }

        @AuraEnabled
        public MeetingTimeSlot meetingTimeSlot { get; set; }

        @AuraEnabled
        public List<AttendeeAvailability> attendeeAvailability {
            get;
            set;
        }
    }

    public class MeetingTimeSlot {

        @AuraEnabled
        public GraphDateTime start { get; set; }

        @AuraEnabled
        public GraphDateTime endval { get; set; }
    }

    public class GraphDateTime {

        @AuraEnabled
        public String dateTimeValue { get; set; }

        @AuraEnabled
        public String timeZone { get; set; }
    }

    public class AttendeeAvailability {

        @AuraEnabled
        public Attendee attendee { get; set; }

        @AuraEnabled
        public String availability { get; set; }
    }

    public class Attendee {

        @AuraEnabled
        public String type { get; set; }

        @AuraEnabled
        public EmailAddress emailAddress { get; set; }
    }

    public class EmailAddress {

        @AuraEnabled
        public String address { get; set; }

        @AuraEnabled
        public String name { get; set; }
    }

    private class GraphUsersResponse {
        public List<GraphUser> value;
    }

    private class GraphUser {
        public String id;
        public String displayName;
        public String mail;
        public String userPrincipalName;
    }

    private class GraphErrorResponse {
        public GraphError error;
    }

    private class GraphError {
        public String code;
        public String message;
    }

    public class MicrosoftGraphMeetingException extends Exception {
    }
}