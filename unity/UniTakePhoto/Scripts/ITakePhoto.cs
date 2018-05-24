/*
 * @Author: zhen wang 
 * @Date: 2018-04-17 17:10:20 
 * @Last Modified by: zhen wang
 * @Last Modified time: 2018-04-17 17:12:09
 */

namespace tiger.uninative.camera
{
    internal interface ITakePhoto
    {
        void show(string dir, string filename, int width, int height);
    }
}