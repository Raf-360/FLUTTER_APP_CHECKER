import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.WebSocket;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;

public class JavaClientExample {
    public static void main(String[] args) throws Exception {
        // REST: POST an event
        postEvent("http://127.0.0.1:8765/event", "{\"action\":\"increment\",\"source\":\"java-rest\"}");

        // WebSocket: connect and send an event, then listen briefly
        var client = HttpClient.newHttpClient();
        var listener = new SimpleListener();
        WebSocket ws = client.newWebSocketBuilder()
                .connectTimeout(Duration.ofSeconds(3))
                .buildAsync(URI.create("ws://127.0.0.1:8765/ws"), listener)
                .join();

        ws.sendText("{\"action\":\"increment\",\"source\":\"java-ws\"}", true);

        // wait a bit to receive broadcasts
        Thread.sleep(1000);
        ws.sendClose(WebSocket.NORMAL_CLOSURE, "bye");
    }

    static void postEvent(String url, String json) throws Exception {
        var client = HttpClient.newHttpClient();
        var req = HttpRequest.newBuilder(URI.create(url))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json, StandardCharsets.UTF_8))
                .build();
        var res = client.send(req, HttpResponse.BodyHandlers.ofString());
        System.out.println("POST /event -> status " + res.statusCode());
    }

    static class SimpleListener implements WebSocket.Listener {
        @Override
        public void onOpen(WebSocket webSocket) {
            System.out.println("WebSocket opened");
            WebSocket.Listener.super.onOpen(webSocket);
        }

        @Override
        public CompletionStage<?> onText(WebSocket webSocket, CharSequence data, boolean last) {
            System.out.println("Received: " + data);
            return WebSocket.Listener.super.onText(webSocket, data, last);
        }

        @Override
        public void onError(WebSocket webSocket, Throwable error) {
            System.out.println("WebSocket error: " + error);
            WebSocket.Listener.super.onError(webSocket, error);
        }

        @Override
        public CompletionStage<?> onClose(WebSocket webSocket, int statusCode, String reason) {
            System.out.println("WebSocket closed: " + statusCode + " / " + reason);
            return CompletableFuture.completedFuture(null);
        }
    }
}

