package couchtest;

import java.net.URI;

import java.util.ArrayList;
 
import com.couchbase.client.CouchbaseClient;
 
import com.couchbase.client.CouchbaseConnectionFactoryBuilder;
 
public class CouchTest {
	private static String BUCKET = "default";
	private static String BUCKET_PASSWORD = "";
 
	public static void main(String[] args) throws Exception {
		ArrayList<URI> uris = new ArrayList<URI>();
 
		uris.add(URI.create("http://127.0.0.1:9000/pools"));
 
		CouchbaseConnectionFactoryBuilder cfb = new CouchbaseConnectionFactoryBuilder();
 
		CouchbaseClient client = null;
 
		// Create client connection
		try {
			client = new CouchbaseClient(cfb.buildCouchbaseConnection(uris, BUCKET, BUCKET_PASSWORD));
		} catch (Exception e) {
			System.err.println("Error connecting to Couchbase: " + e.getMessage());
			System.exit(1);
		}
 
		System.out.println("Available servers:" + client.getAvailableServers());
		System.out.println("Unavailable server:" + client.getUnavailableServers());
 
		// Shutdown the client
		client.shutdown();
	}
}
