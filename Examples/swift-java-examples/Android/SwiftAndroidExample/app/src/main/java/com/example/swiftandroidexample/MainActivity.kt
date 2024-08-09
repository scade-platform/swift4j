package com.example.swiftandroidexample

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.example.swiftandroidexample.ui.theme.SwiftAndroidExampleTheme

class MainActivity : ComponentActivity() {
    private val greetingText = mutableStateOf("Android")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        initSwiftFoundation()

        enableEdgeToEdge()
        setContent {
            SwiftAndroidExampleTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    Greeting(
                        modifier = Modifier.padding(innerPadding)
                    )
                }
            }
        }


        System.loadLibrary("swift-java-examples")

        val foo = swift_java_examples.Foo()
        foo.request { resp ->
            greetingText.value = resp.message
            200
        }
    }

    private fun initSwiftFoundation(){
        try {
            org.swift.swiftfoundation.SwiftFoundation.Initialize(this, false)
        } catch (err: Exception) {
            Log.e("Swift", "Can't initialize Swift Foundation: $err")
        }
    }

    @Composable
    fun Greeting(modifier: Modifier = Modifier) {
        val text by greetingText
        Text(
            text = "Hello $text!",
            modifier = modifier
        )
    }

    @Preview(showBackground = true)
    @Composable
    fun GreetingPreview() {
        SwiftAndroidExampleTheme {
            Greeting()
        }
    }
}

