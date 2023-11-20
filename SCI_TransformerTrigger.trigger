trigger SCI_TransformerTrigger on Transformer__c(before insert, after insert, before update, after update) {
    Map<String, Integer> maxTrId = new Map<String, Integer>();

    for (Transformer__c tr : Trigger.new) {
        if (Trigger.isBefore) {
            // Sets Transformer ID, if missing
            if (tr.Transformer_ID__c == null || tr.Transformer_ID__c.trim().length() == 0) {
                Integer currentMaxTrId = maxTrId.get(tr.Company__c);

                if (currentMaxTrId == null) {
                    List<Transformer__c> transfs = [
                        SELECT Asset_ID__c
                        FROM Transformer__c
                        WHERE Transformer__c.Company__c = :tr.Company__c
                    ];

                    currentMaxTrId = -1;
                    for (Transformer__c transf : transfs) {
                        currentMaxTrId = Math.max(
                            currentMaxTrId,
                            Integer.valueOf(transf.Asset_ID__c.split('@')[0].split('-')[1])
                        );
                    }
                }

                maxTrId.put(tr.Company__c, ++currentMaxTrId);

                tr.Transformer_ID__c = 'TR-' + String.valueOf(currentMaxTrId).leftPad(5, '0');
            }

            if (Trigger.isInsert) {
                // Sets Asset UUID, if missing
                if (tr.Asset_UUID__c == null || tr.Asset_UUID__c.trim().length() == 0) {
                    tr.Asset_UUID__c = new Uuid().getValue();
                }

                // Checks if Transformer already exists
                List<Transformer__c> alreadyExistingTransformers = [
                    SELECT Id
                    FROM Transformer__c
                    WHERE
                        Transformer__c.Company__c = :tr.Company__c
                        AND Transformer__c.Transformer_ID__c = :tr.Transformer_ID__c
                ];

                if (alreadyExistingTransformers != null && alreadyExistingTransformers.size() != 0) {
                    tr.addError(
                        'Cannot create Transformer record with the same Transformer ID and Company of another record.'
                    );
                }
            }

            // Checks if Equipment Number field is unique into Company
            if (tr.Equipment_Number__c != null && tr.Equipment_Number__c.trim().length() > 0) {
                tr.Equipment_Number__c = tr.Equipment_Number__c.trim();

                List<Transformer__c> alreadyExistingTransformers = [
                    SELECT Id
                    FROM Transformer__c
                    WHERE
                        Transformer__c.Company__c = :tr.Company__c
                        AND Transformer__c.Equipment_Number__c = :tr.Equipment_Number__c
                        AND Id != :tr.Id
                ];

                if (alreadyExistingTransformers != null && alreadyExistingTransformers.size() != 0) {
                    (Trigger.isInsert ? tr : Trigger.oldMap.get(tr.Id))
                        .addError(
                            'Cannot create/update Transformer ' +
                            'record with the same Equipment Number and Company of another record.'
                        );
                }
            }

            // Aligns Condition Group field value with Condition Index field
            if (tr.Condition_Index__c < 1) {
                tr.Condition_Group__c = '0';
            } else if (tr.Condition_Index__c < 2) {
                tr.Condition_Group__c = '1';
            } else if (tr.Condition_Index__c < 3) {
                tr.Condition_Group__c = '2';
            } else if (tr.Condition_Index__c < 4) {
                tr.Condition_Group__c = '3';
            } else if (tr.Condition_Index__c < 5) {
                tr.Condition_Group__c = '4';
            } else {
                tr.Condition_Group__c = '5';
            }
        } else if (Trigger.isInsert) {
            // Creates Transformer
            AM_AssetService.createTransformer(tr.Id);
        } else {
            // Updates Transformer properties
            Transformer__c trOld = Trigger.oldMap.get(tr.Id);

            JSONGenerator jsonGen = JSON.createGenerator(false);
            jsonGen.writeStartObject();

            Boolean hvBushingChanged =
                (tr.HV_Bushing_Manufacturing_Year__c != null &&
                tr.HV_Bushing_Manufacturing_Year__c != trOld.HV_Bushing_Manufacturing_Year__c ||
                tr.HV_Bushing_Manufacturing_Year__c == null &&
                trOld.HV_Bushing_Manufacturing_Year__c != null) ||
                (tr.HV_Bushing_OEM__r != null &&
                tr.HV_Bushing_OEM__r != trOld.HV_Bushing_OEM__r ||
                tr.HV_Bushing_OEM__r == null &&
                trOld.HV_Bushing_OEM__r != null) ||
                (tr.Bushing_HV_Rated_Current__c != null &&
                tr.Bushing_HV_Rated_Current__c != trOld.Bushing_HV_Rated_Current__c ||
                tr.Bushing_HV_Rated_Current__c == null &&
                trOld.Bushing_HV_Rated_Current__c != null) ||
                (tr.HV_Bushing_Type__c != null &&
                tr.HV_Bushing_Type__c != trOld.HV_Bushing_Type__c ||
                tr.HV_Bushing_Type__c == null &&
                trOld.HV_Bushing_Type__c != null);
            Boolean lv1BushingChanged =
                (tr.LV1_Bushing_Manufacturing_Year__c != null &&
                tr.LV1_Bushing_Manufacturing_Year__c != trOld.LV1_Bushing_Manufacturing_Year__c ||
                tr.LV1_Bushing_Manufacturing_Year__c == null &&
                trOld.LV1_Bushing_Manufacturing_Year__c != null) ||
                (tr.LV1_Bushing_OEM__r != null &&
                tr.LV1_Bushing_OEM__r != trOld.LV1_Bushing_OEM__r ||
                tr.LV1_Bushing_OEM__r == null &&
                trOld.LV1_Bushing_OEM__r != null) ||
                (tr.Bushing_LV1_Rated_Current__c != null &&
                tr.Bushing_LV1_Rated_Current__c != trOld.Bushing_LV1_Rated_Current__c ||
                tr.Bushing_LV1_Rated_Current__c == null &&
                trOld.Bushing_LV1_Rated_Current__c != null) ||
                (tr.LV1_Bushing_Type__c != null &&
                tr.LV1_Bushing_Type__c != trOld.LV1_Bushing_Type__c ||
                tr.LV1_Bushing_Type__c == null &&
                trOld.LV1_Bushing_Type__c != null);
            Boolean lv2BushingChanged =
                (tr.LV2_Bushing_Manufacturing_Year__c != null &&
                tr.LV2_Bushing_Manufacturing_Year__c != trOld.LV2_Bushing_Manufacturing_Year__c ||
                tr.LV2_Bushing_Manufacturing_Year__c == null &&
                trOld.LV2_Bushing_Manufacturing_Year__c != null) ||
                (tr.LV2_Bushing_OEM__r != null &&
                tr.LV2_Bushing_OEM__r != trOld.LV2_Bushing_OEM__r ||
                tr.LV2_Bushing_OEM__r == null &&
                trOld.LV2_Bushing_OEM__r != null) ||
                (tr.Bushing_LV2_Rated_Current__c != null &&
                tr.Bushing_LV2_Rated_Current__c != trOld.Bushing_LV2_Rated_Current__c ||
                tr.Bushing_LV2_Rated_Current__c == null &&
                trOld.Bushing_LV2_Rated_Current__c != null) ||
                (tr.LV2_Bushing_Type__c != null &&
                tr.LV2_Bushing_Type__c != trOld.LV2_Bushing_Type__c ||
                tr.LV2_Bushing_Type__c == null &&
                trOld.LV2_Bushing_Type__c != null);
            Boolean tvBushingChanged =
                (tr.TV_Bushing_Manufacturing_Year__c != null &&
                tr.TV_Bushing_Manufacturing_Year__c != trOld.TV_Bushing_Manufacturing_Year__c ||
                tr.TV_Bushing_Manufacturing_Year__c == null &&
                trOld.TV_Bushing_Manufacturing_Year__c != null) ||
                (tr.TV_Bushing_OEM__r != null &&
                tr.TV_Bushing_OEM__r != trOld.TV_Bushing_OEM__r ||
                tr.TV_Bushing_OEM__r == null &&
                trOld.TV_Bushing_OEM__r != null) ||
                (tr.Bushing_TV_Rated_Current__c != null &&
                tr.Bushing_TV_Rated_Current__c != trOld.Bushing_TV_Rated_Current__c ||
                tr.Bushing_TV_Rated_Current__c == null &&
                trOld.Bushing_TV_Rated_Current__c != null) ||
                (tr.TV_Bushing_Type__c != null &&
                tr.TV_Bushing_Type__c != trOld.TV_Bushing_Type__c ||
                tr.TV_Bushing_Type__c == null &&
                trOld.TV_Bushing_Type__c != null);

            if (hvBushingChanged || lv1BushingChanged || lv2BushingChanged || tvBushingChanged) {
                jsonGen.writeFieldName('bushing');
                jsonGen.writeStartObject();

                if (hvBushingChanged) {
                    jsonGen.writeFieldName('hv');
                    jsonGen.writeStartObject();

                    if (tr.HV_Bushing_Manufacturing_Year__c != null) {
                        jsonGen.writeNumberField('manufacturingYear', tr.HV_Bushing_Manufacturing_Year__c);
                    } else {
                        jsonGen.writeNullField('manufacturingYear');
                    }

                    if (tr.HV_Bushing_OEM__r != null) {
                        jsonGen.writeStringField('oem', tr.HV_Bushing_OEM__r.Name);
                    } else {
                        jsonGen.writeNullField('oem');
                    }

                    if (tr.Bushing_HV_Rated_Current__c != null) {
                        jsonGen.writeNumberField('ratedCurrent', tr.Bushing_HV_Rated_Current__c);
                    } else {
                        jsonGen.writeNullField('ratedCurrent');
                    }

                    if (tr.HV_Bushing_Type__c != null) {
                        jsonGen.writeStringField('type', tr.HV_Bushing_Type__c);
                    } else {
                        jsonGen.writeNullField('type');
                    }

                    jsonGen.writeEndObject();
                }

                if (lv1BushingChanged) {
                    jsonGen.writeFieldName('lv1');
                    jsonGen.writeStartObject();

                    if (tr.LV1_Bushing_Manufacturing_Year__c != null) {
                        jsonGen.writeNumberField('manufacturingYear', tr.LV1_Bushing_Manufacturing_Year__c);
                    } else {
                        jsonGen.writeNullField('manufacturingYear');
                    }

                    if (tr.LV1_Bushing_OEM__r != null) {
                        jsonGen.writeStringField('oem', tr.LV1_Bushing_OEM__r.Name);
                    } else {
                        jsonGen.writeNullField('oem');
                    }

                    if (tr.Bushing_LV1_Rated_Current__c != null) {
                        jsonGen.writeNumberField('ratedCurrent', tr.Bushing_LV1_Rated_Current__c);
                    } else {
                        jsonGen.writeNullField('ratedCurrent');
                    }

                    if (tr.LV1_Bushing_Type__c != null) {
                        jsonGen.writeStringField('type', tr.LV1_Bushing_Type__c);
                    } else {
                        jsonGen.writeNullField('type');
                    }

                    jsonGen.writeEndObject();
                }

                if (lv2BushingChanged) {
                    jsonGen.writeFieldName('lv2');
                    jsonGen.writeStartObject();

                    if (tr.LV2_Bushing_Manufacturing_Year__c != null) {
                        jsonGen.writeNumberField('manufacturingYear', tr.LV2_Bushing_Manufacturing_Year__c);
                    } else {
                        jsonGen.writeNullField('manufacturingYear');
                    }

                    if (tr.LV2_Bushing_OEM__r != null) {
                        jsonGen.writeStringField('oem', tr.LV2_Bushing_OEM__r.Name);
                    } else {
                        jsonGen.writeNullField('oem');
                    }

                    if (tr.Bushing_LV2_Rated_Current__c != null) {
                        jsonGen.writeNumberField('ratedCurrent', tr.Bushing_LV2_Rated_Current__c);
                    } else {
                        jsonGen.writeNullField('ratedCurrent');
                    }

                    if (tr.LV2_Bushing_Type__c != null) {
                        jsonGen.writeStringField('type', tr.LV2_Bushing_Type__c);
                    } else {
                        jsonGen.writeNullField('type');
                    }

                    jsonGen.writeEndObject();
                }

                if (tvBushingChanged) {
                    jsonGen.writeFieldName('tv');
                    jsonGen.writeStartObject();

                    if (tr.TV_Bushing_Manufacturing_Year__c != null) {
                        jsonGen.writeNumberField('manufacturingYear', tr.TV_Bushing_Manufacturing_Year__c);
                    } else {
                        jsonGen.writeNullField('manufacturingYear');
                    }

                    if (tr.TV_Bushing_OEM__r != null) {
                        jsonGen.writeStringField('oem', tr.TV_Bushing_OEM__r.Name);
                    } else {
                        jsonGen.writeNullField('oem');
                    }

                    if (tr.Bushing_TV_Rated_Current__c != null) {
                        jsonGen.writeNumberField('ratedCurrent', tr.Bushing_TV_Rated_Current__c);
                    } else {
                        jsonGen.writeNullField('ratedCurrent');
                    }

                    if (tr.TV_Bushing_Type__c != null) {
                        jsonGen.writeStringField('type', tr.TV_Bushing_Type__c);
                    } else {
                        jsonGen.writeNullField('type');
                    }

                    jsonGen.writeEndObject();
                }

                jsonGen.writeEndObject();
            }

            if (tr.Equipment_Number__c != null) {
                jsonGen.writeStringField('equipmentNumber', tr.Equipment_Number__c);
            } else {
                jsonGen.writeNullField('equipmentNumber');
            }

            if (tr.Grid_Frequency__c != null) {
                jsonGen.writeNumberField('gridFrequency', Integer.valueOf(tr.Grid_Frequency__c));
            } else {
                jsonGen.writeNullField('gridFrequency');
            }

            if (tr.Installation_Year__c != null) {
                jsonGen.writeNumberField('installationYear', tr.Installation_Year__c);
            } else {
                jsonGen.writeNullField('installationYear');
            }

            if (tr.Manufacturing_Year__c != null) {
                jsonGen.writeNumberField('manufacturingYear', tr.Manufacturing_Year__c);
            } else {
                jsonGen.writeNullField('manufacturingYear');
            }

            if (tr.Load_Losses_FAT__c != null) {
                jsonGen.writeNumberField('loadLossesFAT', tr.Load_Losses_FAT__c);
            } else {
                jsonGen.writeNullField('loadLossesFAT');
            }

            if (tr.No_Load_Losses_FAT__c != null) {
                jsonGen.writeNumberField('noLoadLossesFAT', tr.No_Load_Losses_FAT__c);
            } else {
                jsonGen.writeNullField('noLoadLossesFAT');
            }

            if (tr.Number_of_cooling_stages__c != null) {
                jsonGen.writeNumberField('numberOfCoolingStages', Integer.valueOf(tr.Number_of_cooling_stages__c));
            } else {
                jsonGen.writeNullField('numberOfCoolingStages');
            }

            if (tr.Number_of_Phases__c != null) {
                jsonGen.writeNumberField('numberOfPhases', Integer.valueOf(tr.Number_of_Phases__c));
            } else {
                jsonGen.writeNullField('numberOfPhases');
            }

            if (tr.Number_of_Windings__c != null) {
                jsonGen.writeNumberField('numberOfWindings', Integer.valueOf(tr.Number_of_Windings__c));
            } else {
                jsonGen.writeNullField('numberOfWindings');
            }

            if (tr.External_Cooling__c != null) {
                jsonGen.writeStringField('externalCooling', tr.External_Cooling__c);
            } else {
                jsonGen.writeNullField('externalCooling');
            }

            if (tr.Internal_Cooling__c != null) {
                jsonGen.writeStringField('internalCooling', tr.Internal_Cooling__c);
            } else {
                jsonGen.writeNullField('internalCooling');
            }

            if (tr.Oil_Protection_System__c != null) {
                jsonGen.writeStringField('oilProtectionSystem', tr.Oil_Protection_System__c);
            } else {
                jsonGen.writeNullField('oilProtectionSystem');
            }

            if (tr.Oil_Type__c != null) {
                jsonGen.writeStringField('oilType', tr.Oil_Type__c);
            } else {
                jsonGen.writeNullField('oilType');
            }

            Boolean detcAvailable =
                (tr.DETC_OEM__c != null &&
                tr.DETC_OEM__c != trOld.DETC_OEM__c ||
                tr.DETC_OEM__c == null &&
                trOld.DETC_OEM__c != null) ||
                (tr.DETC_Installation_Side__c != null &&
                tr.DETC_Installation_Side__c != trOld.DETC_Installation_Side__c ||
                tr.DETC_Installation_Side__c == null &&
                trOld.DETC_Installation_Side__c != null);

            if (detcAvailable) {
                jsonGen.writeFieldName('detc');
                jsonGen.writeStartObject();

                if (tr.DETC_OEM__c != null) {
                    jsonGen.writeStringField('oem', tr.DETC_OEM__c);
                } else {
                    jsonGen.writeNullField('oem');
                }

                if (tr.DETC_Installation_Side__c != null) {
                    jsonGen.writeStringField('installationSide', tr.DETC_Installation_Side__c);
                } else {
                    jsonGen.writeNullField('installationSide');
                }

                jsonGen.writeEndObject();
            }

            Boolean oltcChanged =
                (tr.OLTC_OEM__c != null &&
                tr.OLTC_OEM__c != trOld.OLTC_OEM__c ||
                tr.OLTC_OEM__c == null &&
                trOld.OLTC_OEM__c != null) ||
                (tr.OLTC_Installation_Side__c != null &&
                tr.OLTC_Installation_Side__c != trOld.OLTC_Installation_Side__c ||
                tr.OLTC_Installation_Side__c == null &&
                trOld.OLTC_Installation_Side__c != null) ||
                (tr.OLTC_Diverter_Switch_Design__c != null &&
                tr.OLTC_Diverter_Switch_Design__c != trOld.OLTC_Diverter_Switch_Design__c ||
                tr.OLTC_Diverter_Switch_Design__c == null &&
                trOld.OLTC_Diverter_Switch_Design__c != null) ||
                (tr.OLTC_Diverter_Switch_Technology__c != null &&
                tr.OLTC_Diverter_Switch_Technology__c != trOld.OLTC_Diverter_Switch_Technology__c ||
                tr.OLTC_Diverter_Switch_Technology__c == null &&
                trOld.OLTC_Diverter_Switch_Technology__c != null) ||
                (tr.OLTC_Installation_Position__c != null &&
                tr.OLTC_Installation_Position__c != trOld.OLTC_Installation_Position__c ||
                tr.OLTC_Installation_Position__c == null &&
                trOld.OLTC_Installation_Position__c != null) ||
                (tr.OLTC_Switching_Type__c != null &&
                tr.OLTC_Switching_Type__c != trOld.OLTC_Switching_Type__c ||
                tr.OLTC_Switching_Type__c == null &&
                trOld.OLTC_Switching_Type__c != null) ||
                (tr.OLTC_Type__c != null &&
                tr.OLTC_Type__c != trOld.OLTC_Type__c ||
                tr.OLTC_Type__c == null &&
                trOld.OLTC_Type__c != null);

            if (oltcChanged) {
                jsonGen.writeFieldName('oltc');
                jsonGen.writeStartObject();

                if (tr.OLTC_Diverter_Switch_Technology__c != null) {
                    jsonGen.writeStringField('diverterSwitchTechnology', tr.OLTC_Diverter_Switch_Technology__c);
                } else {
                    jsonGen.writeNullField('diverterSwitchTechnology');
                }

                if (tr.OLTC_OEM__c != null) {
                    jsonGen.writeStringField('oem', tr.OLTC_OEM__c);
                } else {
                    jsonGen.writeNullField('oem');
                }

                if (tr.OLTC_Installation_Side__c != null) {
                    jsonGen.writeStringField('installationSide', tr.OLTC_Installation_Side__c);
                } else {
                    jsonGen.writeNullField('installationSide');
                }

                if (tr.OLTC_Diverter_Switch_Design__c != null) {
                    jsonGen.writeStringField('diverterSwitchDesign', tr.OLTC_Diverter_Switch_Design__c);
                } else {
                    jsonGen.writeNullField('diverterSwitchDesign');
                }

                if (tr.OLTC_Diverter_Switch_Technology__c != null) {
                    jsonGen.writeStringField('diverterSwitchTechnology', tr.OLTC_Diverter_Switch_Technology__c);
                } else {
                    jsonGen.writeNullField('diverterSwitchTechnology');
                }

                if (tr.OLTC_Installation_Position__c != null) {
                    jsonGen.writeStringField('installationPosition', tr.OLTC_Installation_Position__c);
                } else {
                    jsonGen.writeNullField('installationPosition');
                }

                if (tr.OLTC_Switching_Type__c != null) {
                    jsonGen.writeStringField('switchingType', tr.OLTC_Switching_Type__c);
                } else {
                    jsonGen.writeNullField('switchingType');
                }

                if (tr.OLTC_Type__c != null) {
                    jsonGen.writeStringField('type', tr.OLTC_Type__c);
                } else {
                    jsonGen.writeNullField('type');
                }

                jsonGen.writeEndObject();
            }

            if (tr.Max_Rating__c != null) {
                jsonGen.writeNumberField('maxRating', tr.Max_Rating__c);
            } else {
                jsonGen.writeNullField('maxRating');
            }

            if (tr.Rated_Voltage_HV__c != null) {
                jsonGen.writeNumberField('ratedVoltageHV', tr.Rated_Voltage_HV__c);
            } else {
                jsonGen.writeNullField('ratedVoltageHV');
            }

            if (tr.Rated_Voltage_LV1__c != null) {
                jsonGen.writeNumberField('ratedVoltageLV1', tr.Rated_Voltage_LV1__c);
            } else {
                jsonGen.writeNullField('ratedVoltageLV1');
            }

            if (tr.Rated_Voltage_LV2__c != null) {
                jsonGen.writeNumberField('ratedVoltageLV2', tr.Rated_Voltage_LV2__c);
            } else {
                jsonGen.writeNullField('ratedVoltageLV2');
            }

            if (tr.Rated_Voltage_TV__c != null) {
                jsonGen.writeNumberField('ratedVoltageTV', tr.Rated_Voltage_TV__c);
            } else {
                jsonGen.writeNullField('ratedVoltageTV');
            }

            if (tr.Serial_Number__c != null) {
                jsonGen.writeStringField('serialNumber', tr.Serial_Number__c);
            } else {
                jsonGen.writeNullField('serialNumber');
            }

            if (tr.Transformer_OEM__r != null) {
                jsonGen.writeStringField('oem', tr.Transformer_OEM__r.Name);
            } else {
                jsonGen.writeNullField('oem');
            }

            if (tr.Location__r != null) {
                jsonGen.writeStringField('timeZone', tr.Location__r.Time_Zone__c);
            } else {
                jsonGen.writeNullField('timeZone');
            }

            if (tr.Tertiary__c != null) {
                jsonGen.writeBooleanField('tertiary', tr.Tertiary__c == 'Y');
            } else {
                jsonGen.writeNullField('tertiary');
            }

            jsonGen.writeEndObject();

            AM_AssetService.updateTransformerProperties(tr.Asset_ID__c, jsonGen.getAsString());
        }
    }
}