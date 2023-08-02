package com.example.google_fit_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.fitness.FitnessOptions
import com.google.android.gms.fitness.data.*
import com.google.android.gms.fitness.request.DataReadRequest
import com.google.android.gms.fitness.Fitness
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.common.api.GoogleApiActivity
import android.os.Bundle
import android.util.Log
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.Instant
import java.util.concurrent.TimeUnit
import androidx.annotation.NonNull
import com.google.android.gms.fitness.result.DataReadResponse
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
import com.google.android.gms.tasks.OnSuccessListener
import android.os.Handler
import com.google.android.gms.tasks.Tasks
import org.json.JSONArray
import org.json.JSONObject


class MainActivity: FlutterActivity() {
    private val TAG = "MESSAGE OF APP"
    private val ChannelFit = "flutter.fit.requests";
    private val GOOGLE_FIT_PERMISSIONS_REQUEST_CODE = 1
    private val fitnessOptions = FitnessOptions.builder()
        .addDataType(DataType.TYPE_HEART_RATE_BPM, FitnessOptions.ACCESS_READ)
        .addDataType(DataType.TYPE_SLEEP_SEGMENT, FitnessOptions.ACCESS_READ)
        .addDataType(DataType.TYPE_STEP_COUNT_DELTA, FitnessOptions.ACCESS_READ)
        .addDataType(DataType.TYPE_WEIGHT, FitnessOptions.ACCESS_READ)
        .addDataType(DataType.TYPE_NUTRITION, FitnessOptions.ACCESS_READ)
        .build()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ChannelFit).setMethodCallHandler { call, result ->
            if(call.method == "getHealthData") {
                val account = GoogleSignIn.getAccountForExtension(this, fitnessOptions)
                if (!GoogleSignIn.hasPermissions(account, fitnessOptions)) {
                    GoogleSignIn.requestPermissions(
                        this,
                        GOOGLE_FIT_PERMISSIONS_REQUEST_CODE,
                        account,
                        fitnessOptions)
                } else {
                    val end = LocalDateTime.now()
                    val start = end.minusWeeks(1)
                    val endSeconds = end.atZone(ZoneId.systemDefault()).toEpochSecond()
                    val startSeconds = start.atZone(ZoneId.systemDefault()).toEpochSecond()

                    val readRequest = DataReadRequest.Builder()
                        .read(DataType.TYPE_STEP_COUNT_DELTA)
                        .setTimeRange(startSeconds, endSeconds, TimeUnit.SECONDS)
                        .build()


                    Fitness.getHistoryClient(this, GoogleSignIn.getAccountForExtension(this, fitnessOptions))
                        .readData(readRequest)
                        .addOnSuccessListener { response ->

                            val dataSet = response.getDataSet(DataType.TYPE_STEP_COUNT_DELTA)
                            Log.i(TAG, dataSet.toString())
                            Log.i(TAG, dataSet.dataPoints.toString())
                            var stepsWeek = 0
                            for (dataPoint in dataSet.dataPoints) {
                                Log.i(TAG, dataPoint.dataType.name)
                                val fields = dataPoint.dataType.fields
                                for (field in fields) {
                                    val value = dataPoint.getValue(field).asInt()
                                    Log.i(TAG, "${field.name}: $value")
                                    stepsWeek += value
                                }
                            }
                            result.success(stepsWeek.toString())

                            // Do something with totalSteps
                        }
                        .addOnFailureListener { e ->
                            Log.i(TAG, "There was a problem getting steps.", e)
                        }
                        .addOnFailureListener({ e -> Log.d(TAG, "OnFailure()", e) })


                }
            } else if (call.method == "getStepsDay") {
                val account = GoogleSignIn.getAccountForExtension(this, fitnessOptions)
                if (!GoogleSignIn.hasPermissions(account, fitnessOptions)) {
                    GoogleSignIn.requestPermissions(
                        this,
                        GOOGLE_FIT_PERMISSIONS_REQUEST_CODE,
                        account,
                        fitnessOptions)
                } else {

                    Fitness.getHistoryClient(this, GoogleSignIn.getAccountForExtension(this, fitnessOptions))
                        .readDailyTotal(DataType.TYPE_STEP_COUNT_DELTA)
                        .addOnSuccessListener { response ->
                            val stepsDay =
                                response.dataPoints.firstOrNull()?.getValue(Field.FIELD_STEPS)
                                    ?.asInt() ?: 0
                            result.success(stepsDay.toString())
                            // Do something with totalSteps
                        }
                        .addOnFailureListener { e ->
                            Log.i(TAG, "There was a problem getting steps.", e)
                        }
                        .addOnFailureListener({ e -> Log.d(TAG, "OnFailure()", e) })


                }
            } else if (call.method == "getHeight") {
                val account = GoogleSignIn.getAccountForExtension(this, fitnessOptions)
                if (!GoogleSignIn.hasPermissions(account, fitnessOptions)) {
                    GoogleSignIn.requestPermissions(
                        this,
                        GOOGLE_FIT_PERMISSIONS_REQUEST_CODE,
                        account,
                        fitnessOptions)
                } else {

                    val endTime = System.currentTimeMillis()
                    val readHeight = DataReadRequest.Builder()
                        .read(DataType.TYPE_HEIGHT)
                        .setTimeRange(1, endTime, TimeUnit.MILLISECONDS)
                        .build()

                    Fitness.getHistoryClient(
                        this,
                        GoogleSignIn.getAccountForExtension(this, fitnessOptions)
                    )
                        .readData(readHeight)
                        .addOnSuccessListener { response ->

                            val dataSetHeight = response.getDataSet(DataType.TYPE_HEIGHT)
                            for (dataPoint in dataSetHeight.dataPoints) {
                                // Height value will be in meters
                                val heightInMeters =
                                    dataPoint.getValue(Field.FIELD_HEIGHT).asFloat()
                                Log.i(TAG, "Height: $heightInMeters meters")
                                result.success(heightInMeters.toString())
                                // You can do something with the height value here
                            }

                        }
                        .addOnFailureListener { e ->
                            Log.i(TAG, "There was a problem getting Height.", e)
                        }
                        .addOnFailureListener({ e -> Log.d(TAG, "OnFailure()", e) })

                }
            } else {
                result.notImplemented()
            }
        }
    }
}
