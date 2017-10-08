/**
 * Created by Rohan.Gore on 9/26/2017.
 */

public class DataFetchingService {
    public static String fetchDataFROMStaticResource(String resourceName) {
        return [SELECT Id, Body FROM StaticResource WHERE NAME =: resourceName].Body.toString();
    }

    public static String fetchDataFromContentVersion(String cvName) {
        return [SELECT Id, versionData FROM ContentVersion WHERE title =: cvName].versionData.toString();
    }
}