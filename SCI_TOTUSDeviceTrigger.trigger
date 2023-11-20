trigger SCI_TOTUSDeviceTrigger on TOTUS_Device__c(
    before insert,
    after insert,
    before update,
    after update,
    before delete
) {
    if (Trigger.isDelete) {
        // Makes post-deletion calls
        for (TOTUS_Device__c td : Trigger.old) {
            AM_AssetService.removeTOTUSDevice(td.Id);
        }

        return;
    }

    for (TOTUS_Device__c td : Trigger.new) {
        if (Trigger.isBefore) {
            List<TOTUS_Device__c> alreadyExistingTOTUSDevices;

            if (Trigger.isUpdate) {
                // Makes pre-update checks
                TOTUS_Device__c tdOld = Trigger.oldMap.get(td.Id);

                if (td.TOTUS_Serial_ID__c != tdOld.TOTUS_Serial_ID__c) {
                    tdOld.addError(
                        'Cannot change TOTUS device Serial ID: remove TOTUS connection first, then introduce a new ' +
                        'one with the correct Serial ID.'
                    );
                }

                if (td.Multiasset_Channel__c != tdOld.Multiasset_Channel__c) {
                    tdOld.addError(
                        'Cannot change TOTUS device Multiasset Channel: remove TOTUS connection first, then ' +
                        'introduce a new one with the correct Multiasset Channel.'
                    );
                }

                if (td.Activation_Time__c == null && tdOld.Activation_Time__c != null) {
                    tdOld.addError('Cannot unset activation time about a TOTUS device connection.');
                }

                if (td.Deactivation_Time__c == null && tdOld.Deactivation_Time__c != null) {
                    tdOld.addError('Cannot unset deactivation time about a TOTUS device connection.');
                }
            } else {
                // Makes pre-insertion checks
                alreadyExistingTOTUSDevices = [
                    SELECT Id
                    FROM TOTUS_Device__c
                    WHERE TOTUS_Serial_ID__c = :td.TOTUS_Serial_ID__c AND Is_Multiasset__c != :td.Is_Multiasset__c
                ];

                if (alreadyExistingTOTUSDevices != null && alreadyExistingTOTUSDevices.size() != 0) {
                    td.addError(
                        'A TOTUS device connection about the same device, with a ' +
                        'different value of Is Multiasset flag has been found. It is not possible to create the record.'
                    );
                }

                if (td.Is_Multiasset__c == true) {
                    alreadyExistingTOTUSDevices = [
                        SELECT Id
                        FROM TOTUS_Device__c
                        WHERE
                            TOTUS_Serial_ID__c = :td.TOTUS_Serial_ID__c
                            AND Transformer__c != :td.Transformer__c
                            AND Activation_Time__c = :td.Activation_Time__c
                            AND Deactivation_Time__c = :td.Deactivation_Time__c
                            AND Multiasset_Channel__c = :td.Multiasset_Channel__c
                    ];

                    if (alreadyExistingTOTUSDevices != null && alreadyExistingTOTUSDevices.size() != 0) {
                        td.addError(
                            'A TOTUS device connection about the same device and same ' +
                            'time span, about a different transformer but the same Multiasset Channel has been ' +
                            'found. It is not possible to create the record.'
                        );
                    }
                }

                alreadyExistingTOTUSDevices = [
                    SELECT Id
                    FROM TOTUS_Device__c
                    WHERE
                        Id != :td.Id
                        AND TOTUS_Serial_ID__c = :td.TOTUS_Serial_ID__c
                        AND Transformer__c = :td.Transformer__c
                        AND (Activation_Time__c = :td.Activation_Time__c
                        OR Deactivation_Time__c = :td.Deactivation_Time__c)
                ];

                if (alreadyExistingTOTUSDevices != null && alreadyExistingTOTUSDevices.size() != 0) {
                    td.addError('Cannot create TOTUS device connection with the same data of another record.');
                }
            }

            // Makes checks common to TOTUS Device insertion and update
            if (td.Activation_Time__c != null) {
                alreadyExistingTOTUSDevices = [
                    SELECT Id
                    FROM TOTUS_Device__c
                    WHERE
                        Id != :td.Id
                        AND TOTUS_Serial_ID__c = :td.TOTUS_Serial_ID__c
                        AND Transformer__c = :td.Transformer__c
                        AND (Activation_Time__c = NULL
                        OR Activation_Time__c < :td.Activation_Time__c)
                        AND (Deactivation_Time__c = NULL
                        OR Deactivation_Time__c > :td.Activation_Time__c)
                ];
            }

            if (
                td.Deactivation_Time__c != null &&
                (alreadyExistingTOTUSDevices == null ||
                alreadyExistingTOTUSDevices.size() == 0)
            ) {
                alreadyExistingTOTUSDevices = [
                    SELECT Id
                    FROM TOTUS_Device__c
                    WHERE
                        Id != :td.Id
                        AND TOTUS_Serial_ID__c = :td.TOTUS_Serial_ID__c
                        AND Transformer__c = :td.Transformer__c
                        AND (Deactivation_Time__c = NULL
                        OR Deactivation_Time__c > :td.Deactivation_Time__c)
                        AND (Activation_Time__c = NULL
                        OR Activation_Time__c < :td.Deactivation_Time__c)
                ];
            }

            if (
                td.Activation_Time__c == null &&
                td.Deactivation_Time__c == null &&
                (alreadyExistingTOTUSDevices == null ||
                alreadyExistingTOTUSDevices.size() == 0)
            ) {
                alreadyExistingTOTUSDevices = [
                    SELECT Id
                    FROM TOTUS_Device__c
                    WHERE
                        Id != :td.Id
                        AND TOTUS_Serial_ID__c = :td.TOTUS_Serial_ID__c
                        AND Transformer__c = :td.Transformer__c
                ];
            }

            if (alreadyExistingTOTUSDevices != null && alreadyExistingTOTUSDevices.size() != 0) {
                if (Trigger.isUpdate) {
                    Trigger.oldMap
                        .get(td.Id)
                        .addError(
                            'A TOTUS device connection about the same transformer with ' +
                            'overlapped time has been found. It is not possible to create/update current record.'
                        );
                } else {
                    td.addError(
                        'A TOTUS device connection about the same transformer with ' +
                        'overlapped time has been found. It is not possible to create/update current record.'
                    );
                }
            }

            alreadyExistingTOTUSDevices = [
                SELECT Id
                FROM TOTUS_Device__c
                WHERE
                    Id != :td.Id
                    AND TOTUS_Serial_ID__c = :td.TOTUS_Serial_ID__c
                    AND Transformer__c != :td.Transformer__c
                    AND Activation_Time__c = :td.Activation_Time__c
                    AND Deactivation_Time__c != :td.Deactivation_Time__c
            ];

            if (alreadyExistingTOTUSDevices != null && alreadyExistingTOTUSDevices.size() != 0) {
                if (Trigger.isUpdate) {
                    Trigger.oldMap
                        .get(td.Id)
                        .addError(
                            'A TOTUS device connection about the same device related to ' +
                            'another transformer, with same activation time but different deactivation time, has been ' +
                            'found. It is not possible to create/update current record. Please, set coherent ' +
                            'deactivation times.'
                        );
                } else {
                    td.addError(
                        'A TOTUS device connection about the same device related to ' +
                        'another transformer, with same activation time but different deactivation time, has been ' +
                        'found. It is not possible to create/update current record. Please, set coherent ' +
                        'deactivation times.'
                    );
                }
            }

            alreadyExistingTOTUSDevices = [
                SELECT Id
                FROM TOTUS_Device__c
                WHERE
                    Id != :td.Id
                    AND TOTUS_Serial_ID__c = :td.TOTUS_Serial_ID__c
                    AND Transformer__c != :td.Transformer__c
                    AND Deactivation_Time__c = :td.Deactivation_Time__c
                    AND Activation_Time__c != :td.Activation_Time__c
            ];

            if (alreadyExistingTOTUSDevices != null && alreadyExistingTOTUSDevices.size() != 0) {
                if (Trigger.isUpdate) {
                    Trigger.oldMap
                        .get(td.Id)
                        .addError(
                            'A TOTUS device connection about the same device related to ' +
                            'another transformer, with same deactivation time but different activation time, has been ' +
                            'found. It is not possible to create/update current record. Please, set coherent activation ' +
                            'times.'
                        );
                } else {
                    td.addError(
                        'A TOTUS device connection about the same device related to another transformer, ' +
                        'with same deactivation time but different activation time, has been found. It is not ' +
                        'possible to create/update current record. Please, set coherent activation times.'
                    );
                }
            }
        } else if (Trigger.isInsert) {
            // Makes post-insertion call
            AM_AssetService.createTOTUSDevice(td.Id);
        } else {
            // Makes post-update calls
            TOTUS_Device__c tdOld = Trigger.oldMap.get(td.Id);

            // Updates activation time
            if (td.Activation_Time__c != tdOld.Activation_Time__c) {
                AM_AssetService.updateTOTUSDeviceActivationTime(
                    tdOld.Transformer__c,
                    tdOld.TOTUS_Serial_ID__c,
                    tdOld.Deactivation_Time__c,
                    td.Activation_Time__c
                );
            }

            // Updates deactivation time
            if (td.Deactivation_Time__c != tdOld.Deactivation_Time__c) {
                AM_AssetService.updateTOTUSDeviceDeactivationTime(
                    tdOld.Transformer__c,
                    tdOld.TOTUS_Serial_ID__c,
                    tdOld.Activation_Time__c,
                    td.Deactivation_Time__c
                );
            }

            // Update TOTUS Device properties
            Boolean dgaChanged =
                (td.Is_Multitank__c != null &&
                td.Is_Multitank__c != tdOld.Is_Multitank__c ||
                td.Is_Multitank__c == null &&
                tdOld.Is_Multitank__c != null) ||
                (td.DGA_Source_A__c != null &&
                td.DGA_Source_A__c != tdOld.DGA_Source_A__c ||
                td.DGA_Source_A__c == null &&
                tdOld.DGA_Source_A__c != null) ||
                (td.DGA_Source_B__c != null &&
                td.DGA_Source_B__c != tdOld.DGA_Source_B__c ||
                td.DGA_Source_B__c == null &&
                tdOld.DGA_Source_B__c != null) ||
                (td.DGA_Source_C__c != null &&
                td.DGA_Source_C__c != tdOld.DGA_Source_C__c ||
                td.DGA_Source_C__c == null &&
                tdOld.DGA_Source_C__c != null);
            Boolean loadSensorChanged =
                (td.Load_Sensor_Installation_Side__c != null &&
                td.Load_Sensor_Installation_Side__c != tdOld.Load_Sensor_Installation_Side__c) ||
                (td.Load_Sensor_Installation_Side__c == null &&
                tdOld.Load_Sensor_Installation_Side__c != null);

            if (dgaChanged || loadSensorChanged) {
                List<Transformer__c> trList = [SELECT Asset_ID__c FROM Transformer__c WHERE Id = :td.Transformer__c];

                if (trList == null || trList.size() == 0) {
                    return;
                }

                JSONGenerator jsonGen = JSON.createGenerator(false);
                jsonGen.writeStartObject();

                if (dgaChanged) {
                    jsonGen.writeFieldName('dga');
                    jsonGen.writeStartObject();

                    if (td.Is_Multitank__c != null) {
                        jsonGen.writeBooleanField('isMultitank', td.Is_Multitank__c);
                    } else {
                        jsonGen.writeNullField('isMultitank');
                    }

                    if (td.DGA_Source_A__c != null) {
                        jsonGen.writeStringField('sampleSourceA', td.DGA_Source_A__c);
                    } else {
                        jsonGen.writeNullField('sampleSourceA');
                    }

                    if (td.DGA_Source_B__c != null) {
                        jsonGen.writeStringField('sampleSourceB', td.DGA_Source_B__c);
                    } else {
                        jsonGen.writeNullField('sampleSourceB');
                    }

                    if (td.DGA_Source_C__c != null) {
                        jsonGen.writeStringField('sampleSourceC', td.DGA_Source_C__c);
                    } else {
                        jsonGen.writeNullField('sampleSourceC');
                    }

                    jsonGen.writeEndObject();
                }

                if (loadSensorChanged) {
                    jsonGen.writeFieldName('loadSensor');
                    jsonGen.writeStartObject();

                    if (td.Load_Sensor_Installation_Side__c != null) {
                        jsonGen.writeStringField('installationSide', td.Load_Sensor_Installation_Side__c);
                    } else {
                        jsonGen.writeNullField('installationSide');
                    }

                    jsonGen.writeEndObject();
                }

                jsonGen.writeEndObject();

                AM_AssetService.updateTOTUSDeviceProperties(
                    td.Transformer__c,
                    td.TOTUS_Serial_ID__c,
                    tdOld.Deactivation_Time__c,
                    td.Activation_Time__c,
                    jsonGen.getAsString()
                );
            }
        }
    }
}