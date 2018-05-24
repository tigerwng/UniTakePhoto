/*
 * @Author: zhen wang 
 * @Date: 2018-04-27 12:36:04 
 * @Last Modified by: zhen wang
 * @Last Modified time: 2018-04-30 12:20:25
 */

#if UNITY_IOS
using UnityEngine;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode;
using System.Diagnostics;
using System.IO;
using Debug = UnityEngine.Debug;

namespace tiger.uninative.camera
{
    public class XcodeProjectConfigurator
    {
        [PostProcessBuild]
        static void OnPostprocessBuild(BuildTarget buildTarget, string buildPath)
        {
            if (buildTarget != BuildTarget.iOS)
                return;

            ConfigurePlist(buildPath, "Info.plist");
        }

        static void ConfigurePlist(string buildPath, string plistPath)
        {
            var plist = new PlistDocument();
            var path = Path.Combine(buildPath, plistPath);

            plist.ReadFromFile(path);

            var descriptionFilePath = Path.Combine(Application.dataPath, "Add-Ons/UniTakePhoto/Editor/NSCameraUsageDescription.txt");
            if (!File.Exists(descriptionFilePath))
            {
                Debug.LogError(string.Format("[UniTakePhoto]:File {0} is not found.", descriptionFilePath));
                return;
            }

            var description = File.ReadAllText(descriptionFilePath);

            plist.root.SetString("NSCameraUsageDescription", description);
            Debug.Log(string.Format("[UniTakePhoto]:Set NSCameraUsageDescription as \"{0}\"", description));

            // add URL Scheme
            var array = plist.root.CreateArray("CFBundleURLTypes");
            var urlDict = array.AddDict();
            urlDict.SetString("CFBundleTypeRole", "Editor");
            urlDict.SetString("CFBundleURLName", "google");
            var urlInnerArray = urlDict.CreateArray("CFBundleURLSchemes");
            urlInnerArray.AddString("com.googleusercontent.apps.170387359759-rg9rjm08j8urqugf78nnescoauigmb5p");

            plist.WriteToFile(path);
        }
    }
}
#endif