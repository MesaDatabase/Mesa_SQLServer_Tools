select * from sys.extended_properties


EXECUTE sp_addextendedproperty @name = N'sys_data_classification_recommendation_disabled', @value = 1, @level0type = N'SCHEMA', @level0name = N'Akc', @level1type = N'TABLE', @level1name = N'DimLendingAddress', @level2type = N'COLUMN', @level2name = N'AddressStatusCode';
GO