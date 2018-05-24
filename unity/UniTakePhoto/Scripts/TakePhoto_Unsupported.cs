/*
 * @Author: zhen wang 
 * @Date: 2018-04-26 10:39:06 
 * @Last Modified by: zhen wang
 * @Last Modified time: 2018-04-26 10:42:04
 */


using UnityEngine;

namespace tiger.uninative.camera
{
    internal class TakePhoto_Unsupported : ITakePhoto
    {
        public void show(string dir, string filename, int width, int height)
        {
            var message = "Unitakephoto is not supported on this platform.";
            Debug.LogError(message);

            var receiver = GameObject.Find("Uninative.TakePhoto");
            if (receiver != null)
            {
                receiver.SendMessage("OnFailure", message);
            }
        }
    }
}