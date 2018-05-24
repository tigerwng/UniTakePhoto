/*
 * @Author: zhen wang 
 * @Date: 2018-04-26 10:33:58 
 * @Last Modified by: zhen wang
 * @Last Modified time: 2018-04-26 10:44:11
 */


#if UNITY_IOS
using System.Runtime.InteropServices;

namespace tiger.uninative.camera
{
    internal class TakePhoto_IOS : ITakePhoto
    {
        [DllImport("__Internal")]
        private static extern void unitakephoto_show(string dir, string filename, int width, int height);

        public void show(string dir, string filename, int width, int height)
        {
            unitakephoto_show(dir, filename, width, height);
        }
    }
}

#endif