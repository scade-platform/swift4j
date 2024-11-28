package com.example.swiftandroidexample

import android.os.Bundle
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

import swift_java_examples.GreetingService

class MainActivity : ComponentActivity() {
    private val greetingText = mutableStateOf("Greeting message")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

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


        // ----- Calling swift-examples demo
        System.loadLibrary("swift-java-examples")

        val foo = swift_java_examples.Greeting("Foo")
        greetingText.value = foo.message

        val greetings = GreetingService()
        greetings.greetAsync("Android", 2) {
            greetingText.value = it.message
        }
        // -----------------------------------

    }

    @Composable
    fun Greeting(modifier: Modifier = Modifier) {
        val text by greetingText
        Text(
            text = "$text!",
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

