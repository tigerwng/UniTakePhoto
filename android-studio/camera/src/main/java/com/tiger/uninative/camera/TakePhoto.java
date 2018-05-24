package com.tiger.uninative.camera;


import android.app.Activity;
import android.app.Fragment;
import android.app.FragmentTransaction;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.support.annotation.Nullable;
import android.support.v4.content.FileProvider;
import android.util.Log;
import com.unity3d.player.UnityPlayer;
import com.unity3d.player.UnityPlayerActivity;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;


/**
 * A simple {@link Fragment} subclass.
 */
@SuppressWarnings("unused")
public class TakePhoto extends Fragment {

    private static final String TAG = "uninative.takephoto";

    private static final String CALLBACK_OBJECT = "Uninative.TakePhoto";
    private static final String CALLBACK_COMPLETE_METHOD = "OnComplete";
    private static final String CALLBACL_FAILURE_METHOD = "OnFailure";

    private static int CODE_TAKE_PHOTO = 1;

    private String outputDirPath;
    private String outputFileName;

    private int requestWidth = 0;
    private int requestHeight = 0;

    private Context context;

    /**
     * 调用TakePhoto
     * @param dir 保存的目录路径
     * @param filename 保存的文件名
     * @param width 图片的宽度。如果值为0的话，则不压缩
     * @param height 图片的高度。如果值为0的话，则不压缩*/
    @SuppressWarnings("unused")
    public static void show(String dir, String filename, int width, int height) {
        Activity currentActivity = UnityPlayer.currentActivity;

        if(currentActivity == null){
            TakePhoto.NotifyFailure("Failed to get current activity");
            return;
        }

        TakePhoto takePhoto = new TakePhoto();

        // 如果参数为null时，使用应用的私有目录下的私有文件目录
        if (dir.equals("")) {
            dir = currentActivity.getFilesDir().toString();
        }

        takePhoto.outputDirPath = dir;
        takePhoto.outputFileName = filename;
        takePhoto.requestWidth = width;
        takePhoto.requestHeight = height;

        takePhoto.context = currentActivity.getApplicationContext();

        FragmentTransaction transaction = currentActivity.getFragmentManager().beginTransaction();

        transaction.add(takePhoto, TakePhoto.TAG);
        transaction.commit();
    }

    private static void NotifySuccess(String path){
        UnityPlayer.UnitySendMessage(CALLBACK_OBJECT, CALLBACK_COMPLETE_METHOD, path);
    }

    private static void NotifyFailure(String cause){
        UnityPlayer.UnitySendMessage(CALLBACK_OBJECT, CALLBACL_FAILURE_METHOD, cause);
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Intent intent = new Intent();
        intent.setAction(MediaStore.ACTION_IMAGE_CAPTURE);

        File file = new File(outputDirPath, outputFileName);

        Uri uri = Uri.fromFile(file);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            String authority = context.getPackageName() + ".fileProvider";
            uri = FileProvider.getUriForFile(context, authority, file);
        }

//        Log.d("uninative", "uri: " + uri.toString());

        intent.putExtra(MediaStore.EXTRA_OUTPUT, uri);
        startActivityForResult(intent, CODE_TAKE_PHOTO);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
//        Log.d("unity", "request code: " + requestCode);

        if (requestCode != CODE_TAKE_PHOTO)
            return;

        FragmentTransaction transaction = getActivity().getFragmentManager().beginTransaction();
        transaction.remove(this);
        transaction.commit();

        /*
        *  一般如果使用指定了照相时的保存地址的话，data是会为空的
        *  加入使用默认地址存储的话，data内会保存缩略图的二进制数据，但也不是所有设备都会有。
        * */

        // 处理图片 - began
        String path = outputDirPath + "/" + outputFileName;

        // 获取一个压缩后的bitmap(尺寸不变，内存减小)
        Bitmap bitmap = decodeBitmapWithCompress(path);

        // 旋转图片
        bitmap = rotateImage(readPictureDegree(path), bitmap);

        // 缩放图片尺寸并覆盖保存图片
        saveBitmapToPath(scaleBitmap(requestWidth, requestHeight, bitmap), path);

        // 回调返回文件路径
        NotifySuccess(path);

        super.onActivityResult(requestCode, resultCode, data);
    }

    /**
     * 读取bitmap，写入内存时压缩尺寸，避免OOM
     * @param path 图片路径
     * @return 返回一个bitmap*/
    Bitmap decodeBitmapWithCompress(String path) {
        // 读取bitmap
        final BitmapFactory.Options options = new BitmapFactory.Options();
        // inJustDecideBounds为true时，解码bitmap只会返回其高，宽和mime类型, 不会为其申请内存空间
        options.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(path, options);

        // 计算inSampleSize
        if (requestWidth == 0 || requestHeight == 0) {
            options.inSampleSize = 1;
        } else {
            options.inSampleSize = calculateInSampleSize(options, requestWidth, requestHeight);
//            Log.d("unity", "decode bitmap: inSampleSize[" + options.inSampleSize + "]");
        }

        options.inJustDecodeBounds = false; // 压缩图片到内存中

        return BitmapFactory.decodeFile(path, options);
    }

    /**
     * 读取图片属性： 旋转角度
     * @param path 图片的绝对路径
     * @return degree 旋转的角度*/
    int readPictureDegree(String path) {
        int degree = 0;
        try {
            ExifInterface exifInterface = new ExifInterface(path);
            int orientation = exifInterface.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
            switch (orientation) {
                case ExifInterface.ORIENTATION_ROTATE_90:
                    degree = 90;
                    break;
                case ExifInterface.ORIENTATION_ROTATE_180:
                    degree = 180;
                    break;
                case ExifInterface.ORIENTATION_ROTATE_270:
                    degree = 270;
                    break;

            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        return  degree;
    }

    /**
     * 旋转图片
     * @param angle 旋转角度
     * @param bitmap bitmap源
     * @return 返回一个旋转后的bitmap*/
    Bitmap rotateImage(int angle, Bitmap bitmap) {
        // 旋转动作
        Matrix matrix = new Matrix();
        matrix.postRotate(angle);

//        Log.d("unity", "rotate image: " + angle);

        return  Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
    }

    /**
     * 计算inSampleSize的值
     *
     * @param  options
     * 用于获取原图的宽高
     * @param  requestWidth
     * 要求压缩后的图片宽度
     * @param  requestHeight
     * 要求压缩后的图片高度
     * @return
     * 返回计算后的inSampleSize值
     * */
    int calculateInSampleSize(BitmapFactory.Options options, int requestWidth, int requestHeight) {
        // 获取原图的宽高
        final int width = options.outWidth;
        final int height = options.outHeight;
        int inSampleSize = 1;

        if (height > requestHeight || width > requestWidth) {
            final int halfHeight = height / 2;
            final int halfWidth = width / 2;

            // 计算inSampleSize
            while ((halfHeight/inSampleSize) >= requestHeight &&
                    (halfWidth/inSampleSize) >= requestWidth) {
                inSampleSize *= 2;
            }
        }

        return inSampleSize;
    }

    /**
     * 缩放bitmap
     * @param bitmap 需要缩放的bitmap
     * @param heightTo 需要缩放的高度
     * @param widthTo 需要缩放的宽度
     * @return 返回一个缩放后的bitmap*/
    Bitmap scaleBitmap(int widthTo, int heightTo, Bitmap bitmap) {
        if (bitmap == null)
            return null;

        int originWidth = bitmap.getWidth();
        int originHeight = bitmap.getHeight();

        float scaleWidth = (float) widthTo / originWidth;
        float scaleHeight = (float) heightTo / originHeight;

        Matrix matrix = new Matrix();
        matrix.postScale(scaleWidth, scaleHeight);

        Bitmap ret = Bitmap.createBitmap(bitmap, 0, 0, originWidth, originHeight, matrix, false);

//        Log.d("unity", "scale bitmap: [" + scaleWidth + ", " + scaleHeight + "]");

        if (!bitmap.isRecycled())
        {
            bitmap.recycle();
        }

        return ret;
    }

    /**
     * 覆盖保存bitmap
     * @param bitmap 需要保存的bitmap
     * @param path 保存到的路径
     * @return 返回执行的结果*/
    boolean saveBitmapToPath(final Bitmap bitmap, final String path) {
        if (bitmap == null || path == null) {
            return false;
        }

        File file = new File(path);
        OutputStream outputStream = null; // 输出文件流

        try {
            outputStream = new FileOutputStream(file);
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
          if (outputStream != null) {
              try {
                  outputStream.close();
              } catch (IOException e) {
                  e.printStackTrace();
              }
          }
        }

        return  true;
    }


}
