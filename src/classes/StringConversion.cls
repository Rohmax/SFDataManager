/**
 * Created by Rohan.Gore on 9/26/2017.
 */

public with sharing class StringConversion implements DataConversionInterface {
    public Object convert(Object obj) {
        return String.valueOf(obj);
    }
}