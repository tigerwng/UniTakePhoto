/*
 * @Author: zhen wang 
 * @Date: 2018-04-17 17:12:40 
 * @Last Modified by:   zhen wang 
 * @Last Modified time: 2018-04-17 17:12:40 
 */

#if UNITY_ANDROID

using UnityEngine;

namespace tiger.uninative.camera
{
    internal class TakePhoto_Android : ITakePhoto
    {
        private static readonly string TakePhotoClass = "com.tiger.uninative.camera.TakePhoto";

        public void show(string dir, string filename, int width, int height)
        {
            using (var shower = new AndroidJavaClass(TakePhotoClass))
            {
                shower.CallStatic("show", dir, filename, width, height);
            }
        }
    }
}

#endif