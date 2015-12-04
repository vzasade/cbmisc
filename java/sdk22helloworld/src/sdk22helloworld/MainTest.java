package sdk22helloworld;

import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.LogManager;
import java.util.logging.Logger;

import com.couchbase.client.core.logging.CouchbaseLogger;
import com.couchbase.client.core.logging.CouchbaseLoggerFactory;
import com.couchbase.client.java.Bucket;
import com.couchbase.client.java.Cluster;
import com.couchbase.client.java.CouchbaseAsyncCluster;
import com.couchbase.client.java.CouchbaseCluster;
import com.couchbase.client.java.document.JsonDocument;
import com.couchbase.client.java.env.CouchbaseEnvironment;
import com.couchbase.client.java.env.DefaultCouchbaseEnvironment;

public class MainTest {

	public static void main(String[] args) {
		Logger log = LogManager.getLogManager().getLogger("");
		for (Handler h : log.getHandlers()) {
		    h.setLevel(Level.INFO);
		}
		
		CouchbaseEnvironment env = DefaultCouchbaseEnvironment
				.builder()
				.sslEnabled(true)
				.sslKeystoreFile("/Users/artem/Work/cert/javakeystore")
				.sslKeystorePassword("asdasd")
				.bootstrapCarrierDirectPort(12000)
				.bootstrapCarrierSslPort(11996)
				.bootstrapHttpDirectPort(9000)
				.bootstrapHttpSslPort(19000)
				.build();
		
		Cluster cluster = CouchbaseCluster.create(env, "127.0.0.1");
		Bucket bucket = cluster.openBucket("default", "");
		JsonDocument doc = bucket.get("aaa");
		System.out.println("Found: " + doc);
		cluster.disconnect();
	}

}
