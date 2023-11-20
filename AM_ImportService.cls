public with sharing class AM_ImportService {
    private static void creatAssetImportationRequest(
        String companyId,
        String importationRequestId,
        String assetCategory
    ) {
        Account company = SCI_CommonUtils.getCompany(companyId);

        if (company == null)
            throw new IllegalArgumentException();

        Asset_Importation_Request__c impRequest = new Asset_Importation_Request__c(
            Name = importationRequestId,
            Company__c = company.Id,
            Asset_Category__c = assetCategory,
            Progress__c = 0,
            Status__c = 'RUNNING'
        );
        insert impRequest;
    }

    public static void manageCircuitBreakerExistence(
        String companyId,
        String substationName,
        String substationId,
        String circuitBreakerName,
        String circuitBreakerId,
        String timeZone
    ) {
        Account company = SCI_CommonUtils.getCompany(companyId);

        if (company == null)
            throw new IllegalArgumentException();

        String locationId = SCI_CommonUtils.getLocationId(substationId, companyId);
        Asset_Location__c location = SCI_CommonUtils.getLocation(locationId);
        String assetId = SCI_CommonUtils.getAssetId(circuitBreakerId, locationId);

        if (location == null) {
            location = new Asset_Location__c(
                Name = substationName,
                Site_ID__c = substationId,
                Company__c = company.Id,
                Time_Zone__c = timeZone
            );
            insert location;

            Circuit_Breaker__c asset = new Circuit_Breaker__c(
                Name = circuitBreakerName,
                Circuit_Breaker_ID__c = circuitBreakerId,
                Company__c = company.Id,
                Location__c = location.Id
            );
            insert asset;
        } else {
            List<Circuit_Breaker__c> assets = [SELECT Id FROM Circuit_Breaker__c WHERE Asset_ID__c = :assetId];

            if (assets.isEmpty()) {
                Circuit_Breaker__c asset = new Circuit_Breaker__c(
                    Name = circuitBreakerName,
                    Circuit_Breaker_ID__c = circuitBreakerId,
                    Company__c = company.Id,
                    Location__c = location.Id
                );
                insert asset;
            }
        }
    }

    private static HttpRequest createImportRecFileRequest(
        String fileName,
        String timeZone,
        Integer millisOffset,
        Long timestamp,
        String siteId,
        String circuitBreakerId,
        String circuitBreakerType,
        String circuitId
    ) {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(
            'callout:AM_Services/import/api/1/fileImportation/rec?fileName=' +
            EncodingUtil.urlEncode(fileName, 'UTF-8') +
            '&timeZone=' +
            EncodingUtil.urlEncode(timeZone, 'UTF-8') +
            '&millisOffset=' +
            (millisOffset != null ? millisOffset : 0) +
            (timestamp != null && timestamp > 0 ? '&timestamp=' + timestamp : '') +
            '&substationId=' +
            EncodingUtil.urlEncode(siteId, 'UTF-8') +
            '&circuitBreakerId=' +
            EncodingUtil.urlEncode(circuitBreakerId, 'UTF-8') +
            (circuitBreakerType != null
                ? '&circuitBreakerType=' + EncodingUtil.urlEncode(circuitBreakerType, 'UTF-8')
                : '') +
            (circuitId != null ? '&circuitId=' + EncodingUtil.urlEncode(circuitId, 'UTF-8') : '')
        );
        request.setHeader('Content-Type', 'application/octet-stream');
        return request;
    }


    private static String sendCircuitBreakerImportRequest(
        HttpRequest request,
        String companyId,
        String substationName,
        String substationId,
        String circuitBreakerName,
        String circuitBreakerId,
        String timeZone
    ) {
        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 202) {
            String responseContent = response.getBody();

            String importationRequestId = (String) JSON.deserializeUntyped(responseContent);
            creatAssetImportationRequest(companyId, importationRequestId, 'CircuitBreaker');

            manageCircuitBreakerExistence(
                companyId,
                substationName,
                substationId,
                circuitBreakerName,
                circuitBreakerId,
                timeZone
            );

            return responseContent;
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
    }

    private static String doImportRecFile(
        boolean isFileBase64Encoded,
        String selectedCompany,
        String fileName,
        String file,
        String timeZone,
        Integer millisOffset,
        Long timestamp,
        String substationId,
        String circuitBreakerId,
        String circuitBreakerType,
        String circuitId
    ) {
        String companyId = SCI_CommonUtils.getUserCompanyId();

        if (companyId == null || companyId.length() == 0) {
            if (selectedCompany == null || selectedCompany.length() == 0) {
                throw new IllegalArgumentException('Selected company is empty');
            }

            companyId = SCI_CommonUtils.escapeSymbols(selectedCompany);
        }

        if (timeZone == null || timeZone.trim().length() == 0)
            throw new IllegalArgumentException('Missing timezone');

        if (
            fileName == null ||
            fileName.trim().length() == 0 ||
            file == null ||
            file.trim().length() == 0 ||
            companyId == null ||
            companyId.trim().length() == 0 ||
            substationId == null ||
            substationId.trim().length() == 0 ||
            circuitBreakerId == null ||
            circuitBreakerId.trim().length() == 0
        )
            throw new IllegalArgumentException();

        String substationIdValue = SCI_CommonUtils.escapeSymbols(substationId);
        String circuitBreakerIdValue = SCI_CommonUtils.escapeSymbols(circuitBreakerId);

        HttpRequest request = createImportRecFileRequest(
            fileName,
            timeZone,
            millisOffset,
            timestamp,
            substationIdValue +
            ';' +
            companyId,
            circuitBreakerIdValue,
            circuitBreakerType,
            circuitId
        );
        request.setBodyAsBlob(
            isFileBase64Encoded ? EncodingUtil.base64Decode(file) : Blob.valueOf(file.unescapeJava())
        );

        return sendCircuitBreakerImportRequest(
            request,
            companyId,
            substationId,
            substationIdValue,
            circuitBreakerId,
            circuitBreakerIdValue,
            timeZone
        );
    }

    @AuraEnabled(cacheable=true)
    public static String importCsvCircuitBreakers(String file) {
        return 'importCsvCircuitBreakers from an apex class';
    }

    @AuraEnabled(cacheable=true)
    public static String getAssetRecordId(
        String selectedCompany,
        String assetCategory,
        String siteId,
        String bareAssetId
    ) {
        String companyId = SCI_CommonUtils.getUserCompanyId();

        if (companyId == null || companyId.length() == 0) {
            companyId = selectedCompany;
        }

        String locationId = SCI_CommonUtils.getLocationId(
            SCI_CommonUtils.escapeSymbols(siteId),
            SCI_CommonUtils.escapeSymbols(companyId)
        );
        String assetId = SCI_CommonUtils.getAssetId(SCI_CommonUtils.escapeSymbols(bareAssetId), locationId);

        if (assetCategory == 'CircuitBreaker') {
            List<Circuit_Breaker__c> assets = [SELECT Id FROM Circuit_Breaker__c WHERE Asset_ID__c = :assetId];
            return assets.size() == 1 ? ('"' + assets[0].Id + '"') : null;
        }

        if (assetCategory == 'Transformer') {
            List<Transformer__c> assets = [SELECT Id FROM Transformer__c WHERE Asset_ID__c = :assetId];
            return assets.size() == 1 ? ('"' + assets[0].Id + '"') : null;
        }

        return null;
    }

    @AuraEnabled(cacheable=true)
    public static String getAssetLocationRecordId(String selectedCompany, String siteId) {
        String companyId = SCI_CommonUtils.getUserCompanyId();

        if (companyId == null || companyId.length() == 0) {
            companyId = selectedCompany;
        }

        String locationId = SCI_CommonUtils.getLocationId(
            SCI_CommonUtils.escapeSymbols(siteId),
            SCI_CommonUtils.escapeSymbols(companyId)
        );
        Asset_Location__c location = SCI_CommonUtils.getLocation(locationId);

        return location != null ? ('"' + location.Id + '"') : null;
    }

    @AuraEnabled(cacheable=false)
    public static String getImportationStatus(String selectedCompany, String importRequestId) {
        String companyId = SCI_CommonUtils.getUserCompanyId();

        if (companyId == null || companyId.length() == 0) {
            companyId = selectedCompany;
        }

        Account company = SCI_CommonUtils.getCompany(companyId);

        if (company == null)
            return null;

        List<Asset_Importation_Request__c> impRequests = [
            SELECT Asset_Category__c, Status__c, SerialIdOrAssetId__c, Progress__c
            FROM Asset_Importation_Request__c
            WHERE Name = :importRequestId AND Company__c = :company.Id
        ];

        if (impRequests.size() == 1) {
            Asset_Importation_Request__c queryResult = impRequests[0];
            JSONGenerator jsonGen = JSON.createGenerator(false);
            jsonGen.writeStartObject();
            jsonGen.writeStringField('importRequestId', importRequestId);
            jsonGen.writeStringField('assetCategory', queryResult.Asset_Category__c);
            jsonGen.writeStringField('status', queryResult.Status__c);

            if (queryResult.SerialIdOrAssetId__c != null)
                jsonGen.writeStringField('serialIdOrAssetId', queryResult.SerialIdOrAssetId__c);

            if (queryResult.Progress__c != null)
                jsonGen.writeNumberField('progress', queryResult.Progress__c);

            jsonGen.writeEndObject();
            return jsonGen.getAsString();
        }

        return null;
    }

    @AuraEnabled(cacheable=false)
    public static String importRecFile(
        String selectedCompany,
        String fileName,
        String file,
        String timeZone,
        Integer millisOffset,
        Long timestamp,
        String substationId,
        String circuitBreakerId,
        String circuitBreakerType,
        String circuitId
    ) {
        return doImportRecFile(
            false,
            selectedCompany,
            fileName,
            file,
            timeZone,
            millisOffset,
            timestamp,
            substationId,
            circuitBreakerId,
            circuitBreakerType,
            circuitId
        );
    }

    @AuraEnabled(cacheable=false)
    public static String importRecxFile(
        String selectedCompany,
        String fileName,
        String file,
        String timeZone,
        Integer millisOffset,
        Long timestamp,
        String substationId,
        String circuitBreakerId,
        String circuitBreakerType,
        String circuitId
    ) {
        return doImportRecFile(
            true,
            selectedCompany,
            fileName,
            file,
            timeZone,
            millisOffset,
            timestamp,
            substationId,
            circuitBreakerId,
            circuitBreakerType,
            circuitId
        );
    }

    /*@AuraEnabled(cacheable=false)
    public static String importTarFile(String fileName, Blob file) {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('callout:AM_Services/import/api/1/fileImportation/tar?fileName=' + fileName);
        request.setHeader('Content-Type', 'application/octet-stream');
        request.setBodyAsBlob(file);
        return sendImportRequest(request);
    }*/

    @AuraEnabled(cacheable=false)
    public static String validateRecFile(
        String selectedCompany,
        String substationId,
        String circuitBreakerId,
        String circuitBreakerType,
        String circuitId,
        String timeZone,
        Integer millisOffset,
        Long timestamp
    ) {
        String companyId = SCI_CommonUtils.getUserCompanyId();

        if (companyId == null || companyId.length() == 0) {
            companyId = selectedCompany;
        }

        String companyPostfix = ';' + SCI_CommonUtils.escapeSymbols(companyId);
        String substationIdValue = substationId != null ? SCI_CommonUtils.escapeSymbols(substationId) : null;
        String circuitBreakerIdValue = circuitBreakerId != null
            ? SCI_CommonUtils.escapeSymbols(circuitBreakerId)
            : null;

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(
            'callout:AM_Services/import/api/1/fileValidation/rec' +
            '?substationIdPattern=*' +
            EncodingUtil.urlEncode(companyPostfix, 'UTF-8') +
            (substationIdValue != null
                ? '&substationId=' + EncodingUtil.urlEncode(substationIdValue + companyPostfix, 'UTF-8')
                : '') +
            (circuitBreakerIdValue != null
                ? '&circuitBreakerId=' + EncodingUtil.urlEncode(circuitBreakerIdValue, 'UTF-8')
                : '') +
            (circuitBreakerType != null
                ? '&circuitBreakerType=' + EncodingUtil.urlEncode(circuitBreakerType, 'UTF-8')
                : '') +
            (circuitId != null ? '&circuitId=' + EncodingUtil.urlEncode(circuitId, 'UTF-8') : '') +
            (timeZone != null ? '&timeZone=' + EncodingUtil.urlEncode(timeZone, 'UTF-8') : '') +
            '&millisOffset=' +
            (millisOffset != null ? millisOffset : 0) +
            (timestamp != null && timestamp > 0 ? '&timestamp=' + timestamp : '')
        );

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            return SCI_CommonUtils.restoreSymbols(response.getBody().replace(companyPostfix, ''));
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
        //return AM_ImportService_ValidateRecFileMock.VALIDATION_MODEL;
    }
}