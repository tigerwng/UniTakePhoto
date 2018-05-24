/*
 * @Author: zhen wang 
 * @Date: 2018-04-17 17:19:52 
 * @Last Modified by: zhen wang
 * @Last Modified time: 2018-04-27 12:59:46
 */

using UnityEngine;

namespace tiger.uninative.camera
{
    public class UniTakePhoto : MonoBehaviour
    {
        public delegate void CompleteDelegate(string path);
        public delegate void ErrorDelegate(string message);

        public event CompleteDelegate Completed;
        public event ErrorDelegate Failed;

        private ITakePhoto takePhoto = 
        #if UNITY_EDITOR
        new TakePhoto_Unsupported();
        #elif UNITY_ANDROID
        new TakePhoto_Android();
        #elif UNITY_IOS
        new TakePhoto_IOS();
        #endif  

        public void show(string dir, string filename, int width, int height)
        {
            takePhoto.show(dir, filename, width, height);
        }

        public void OnComplete(string path)
        {
            var handler = Completed;
            if(handler != null)
            {
                handler(path);
            }
        }

        public void OnFailure(string message)
        {
            var handler = Failed;
            if(handler != null)
            {
                handler(message);
            }
        }

        
    }
}