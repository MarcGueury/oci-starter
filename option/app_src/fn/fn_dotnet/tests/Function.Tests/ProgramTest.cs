using Function;
using NUnit.Framework;

namespace Function.Tests {
	public class GreeterTest {
		[Test]
		public void TestGreetValid() {
			Greeter greeter = new Greeter();
			string response = greeter.greet("Dotnet");
			Assert.AreEqual("Hello Dotnet!", response);
		}

		[Test]
		public void TestGreetEmpty() {
			Greeter greeter = new Greeter();
			string response = greeter.greet("");
			Assert.AreEqual("Hello World!", response);
		}
	}
}
