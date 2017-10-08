/**
 * Created by Rohan.Gore on 9/26/2017.
 */

public with sharing class DecimalConversion implements DataConversionInterface {
    public Object convert(Object obj) {
        String decimalStrng = String.valueOf(obj);
        return Decimal.valueOf(decimalStrng);

    }
}