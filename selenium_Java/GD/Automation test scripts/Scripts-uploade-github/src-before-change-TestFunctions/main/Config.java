package main;

/**
 * @author Jinhua Huang
 * This class provides a number of configurations which will be used
 * by other classes
 * 
 */

public class Config {

	/** The URL of Saiku web server to test */
	public static String BASE_URL = "http://192.168.128.118:8080";

	/** The URL of selenium hub */
	public static String SELENIUM_URL = "http://192.168.128.118:4444/wd/hub/";

	/** The username and password for login the web server */
	public static String USERNAME = "admin";
	public static String PASSWORD = "admin";

	/** The URL to navigate away from BASE_URL for login cookie test  */
	public static String NAV_URL = "http://google.com";
	public static String NAV_URL_TITLE = "Google";

	/** The window size of browser which is defined by start point and dimension */
	public static int START_POINT[] = {0,0};
	public static int DIMESION[] = {1220, 900};


	/** AutoIT executable files which handle OS download dialog boxes */
	public static String AUTO_IT_EXECUTABLE_IE = "C:/Users/Jinhua/Test/Saiku-UI-test/autoIT/Save_Dialog_IE.exe";
	public static String AUTO_IT_EXECUTABLE_FF = "C:/Users/Jinhua/Test/Saiku-UI-test/autoIT/Save_Dialog_FF.exe";

}
