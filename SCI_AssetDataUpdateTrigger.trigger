trigger SCI_AssetDataUpdateTrigger on SCI_Asset_Data_Update__e(after insert) {
    for (SCI_Asset_Data_Update__e event : Trigger.New) {
        if (event.Data__c.trim().length() == 0) {
            System.debug('Received an SCI_Asset_Data_Update__e event with empty Data field: ' + JSON.serialize(event));
        } else {
            Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(event.Data__c);

            if (dataMap.isEmpty()) {
                System.debug(
                    'Received an SCI_Asset_Data_Update__e event with an empty object as value of Data ' +
                    'field: ' +
                    JSON.serialize(event)
                );
            } else {
                Long timestamp = (Long) dataMap.get('timestamp');

                if (timestamp == null || timestamp == 0) {
                    System.debug(
                        'Received an SCI_Asset_Data_Update__e event with Data field not containing a valid ' +
                        'timestamp: ' +
                        JSON.serialize(event)
                    );
                } else {
                    switch on event.Asset_Category__c {
                        when 'CircuitBreaker' {
                            Circuit_Breaker__c cb = [
                                SELECT Last_Point_Time__c
                                FROM Circuit_Breaker__c
                                WHERE Asset_ID__c = :event.AssetId__c
                                LIMIT 1
                            ];

                            if (cb == null) {
                                System.debug(
                                    'Received an SCI_Asset_Data_Update__e event with an Asset ID which ' +
                                    'doesn\'t match with any Circuit Breaker: ' +
                                    JSON.serialize(event)
                                );
                            } else if (cb.Last_Point_Time__c == null || timestamp >= cb.Last_Point_Time__c) {
                                switch on event.Data_Type__c {
                                    when 'Asset_Data' {
                                        cb.Last_Point_Time__c = timestamp;

                                        try {
                                            update cb;
                                        } catch (Exception e) {
                                            System.debug('SCI_AssetDataUpdateTrigger: ' + e);
                                        }
                                    }
                                    when 'ML_Data' {
                                        String cbModel = (String) dataMap.get('cbModel');

                                        if (cbModel != null && cbModel.trim().length() > 0) {
                                            cb.Circuit_Breaker_Model__c = cbModel;
                                        }

                                        Map<String, Object> cg = (Map<String, Object>) dataMap.get('condition_group');

                                        if (cg == null) {
                                            System.debug(
                                                'Received an SCI_Asset_Data_Update__e event about ML_Data ' +
                                                'as data type, but without "condition_group" field: ' +
                                                JSON.serialize(event)
                                            );

                                            if (cbModel != null && cbModel.trim().length() > 0) {
                                                try {
                                                    update cb;
                                                } catch (Exception e) {
                                                    System.debug('SCI_AssetDataUpdateTrigger: ' + e);
                                                }
                                            }
                                        } else {
                                            Integer status = (Integer) cg.get('status');

                                            if (status != null) {
                                                cb.Last_Point_Time__c = timestamp;
                                                cb.Condition_Index__c = status;
                                                cb.Urgency_Code__c = (String) cg.get('priority');
                                                cb.Defect_Codes__c = JSON.serialize(cg.get('defect'));
                                                cb.ML_Message__c = (String) cg.get('message');

                                                try {
                                                    update cb;
                                                } catch (Exception e) {
                                                    System.debug('SCI_AssetDataUpdateTrigger: ' + e);
                                                }
                                            } else {
                                                System.debug(
                                                    'Received an SCI_Asset_Data_Update__e event about ML_Data ' +
                                                    'as data type, but without "status" data field: ' +
                                                    JSON.serialize(event)
                                                );

                                                if (cbModel != null && cbModel.trim().length() > 0) {
                                                    try {
                                                        update cb;
                                                    } catch (Exception e) {
                                                        System.debug('SCI_AssetDataUpdateTrigger: ' + e);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    when else {
                                        System.debug(
                                            'Received an SCI_Asset_Data_Update__e event with an unknown ' +
                                            'Data Type: ' +
                                            JSON.serialize(event)
                                        );
                                    }
                                }
                            } else {
                                System.debug(
                                    'Received an SCI_Asset_Data_Update__e event with an older timestamp: ' +
                                    JSON.serialize(event)
                                );
                            }
                        }
                        when 'Transformer' {
                            switch on event.Data_Type__c {
                                when 'Asset_Data' {
                                    Transformer__c t = [
                                        SELECT Last_Point_Time__c
                                        FROM Transformer__c
                                        WHERE Asset_ID__c = :event.AssetId__c
                                        LIMIT 1
                                    ];

                                    if (t == null) {
                                        System.debug(
                                            'Received an SCI_Asset_Data_Update__e event with an Asset ID ' +
                                            'which doesn\'t match with any Transformer: ' +
                                            JSON.serialize(event)
                                        );
                                    } else if (t.Last_Point_Time__c == null || timestamp >= t.Last_Point_Time__c) {
                                        t.Last_Point_Time__c = timestamp;

                                        try {
                                            update t;
                                        } catch (Exception e) {
                                            System.debug('SCI_AssetDataUpdateTrigger: ' + e);
                                        }
                                    } else {
                                        System.debug(
                                            'Received an SCI_Asset_Data_Update__e event with an older ' +
                                            'timestamp: ' +
                                            JSON.serialize(event)
                                        );
                                    }
                                }
                                when 'ML_Data' {
                                    Transformer__c t = [
                                        SELECT Last_Point_Time__c, Condition_Index__c
                                        FROM Transformer__c
                                        WHERE Asset_ID__c = :event.AssetId__c
                                        LIMIT 1
                                    ];

                                    if (t == null) {
                                        System.debug(
                                            'Received an SCI_Asset_Data_Update__e event with an Asset ID ' +
                                            'which doesn\'t match with any Transformer: ' +
                                            JSON.serialize(event)
                                        );
                                    } else if (t.Last_Point_Time__c == null || timestamp >= t.Last_Point_Time__c) {
                                        Map<String, Object> cg = (Map<String, Object>) dataMap.get('condition_group');

                                        if (cg == null) {
                                            System.debug(
                                                'Received an SCI_Asset_Data_Update__e event about ML_Data ' +
                                                'as data type, but without "condition_group" field: ' +
                                                JSON.serialize(event)
                                            );
                                        } else {
                                            Double status = (Double) cg.get('status');

                                            if (status != null) {
                                                t.Last_Point_Time__c = timestamp;
                                                t.Condition_Index__c = status;
                                                t.Urgency_Code__c = (String) cg.get('priority');
                                                t.Activities_Codes__c = JSON.serialize(cg.get('action'));

                                                try {
                                                    update t;
                                                } catch (Exception e) {
                                                    System.debug('SCI_AssetDataUpdateTrigger: ' + e);
                                                }
                                            } else {
                                                System.debug(
                                                    'Received an SCI_Asset_Data_Update__e event about ' +
                                                    'ML_Data as data type, but with empty "status" data field: ' +
                                                    JSON.serialize(event)
                                                );
                                            }
                                        }
                                    } else {
                                        System.debug(
                                            'Received an SCI_Asset_Data_Update__e event with an older ' +
                                            'timestamp: ' +
                                            JSON.serialize(event)
                                        );
                                    }
                                }
                                when else {
                                    System.debug(
                                        'Received an SCI_Asset_Data_Update__e event with an unknown Data ' +
                                        'Type: ' +
                                        JSON.serialize(event)
                                    );
                                }
                            }
                        }
                        when else {
                            System.debug(
                                'Received an SCI_Asset_Data_Update__e event with an unknown Asset ' +
                                'Category: ' +
                                JSON.serialize(event)
                            );
                        }
                    }
                }
            }
        }
    }
}