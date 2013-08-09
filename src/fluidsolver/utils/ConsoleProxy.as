package fluidsolver.utils 
{
	import fluidsolver.core.crossbridge.CModule;
	import fluidsolver.core.crossbridge.vfs.ISpecialFile;
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public class ConsoleProxy implements ISpecialFile 
	{
		
		private var _logHandler:Function;
		
		public function ConsoleProxy(logFunction:Function = null) {
			_logHandler = logFunction;
		}
		
		
		/**
		 * This matches the signature of fcntl from the IKernel interface.
		 * @param	fileDescriptor	The file descriptor being manipulated
		 * @param	cmd	An fcntl command
		 * @param	data	An argument for the given command
		 * @param	errnoPtr	A pointer to the location of the errno global variable
		 * @return	an integer indicating the success or failure of the syscall, see the BSD documentation for expected values
		 */
		public function fcntl (fileDescriptor:int, cmd:int, data:int, errnoPtr:int) : int {
			return 0;
		}

		/**
		 * This matches the signature of ioctl from the IKernel interface.
		 * @param	fileDescriptor	The file descriptor being manipulated
		 * @param	request	An ioctl request
		 * @param	data	An argument for the given command
		 * @param	errnoPtr	A pointer to the location of the errno global variable
		 * @return	an integer indicating the success or failure of the syscall, see the BSD documentation for expected values
		 */
		public function ioctl (fileDescriptor:int, request:int, data:int, errnoPtr:int) : int {
			return 0;
		}

		/**
		 * This matches the signature of read from the IKernel interface.
		 * @param	fileDescriptor	The file descriptor being read from
		 * @param	bufPtr	A Pointer to the buffer you are expected to fill with data for this read.
		 * @param	nbyte	The size of the buffer pointed to by bufPtr
		 * @param	errnoPtr	A pointer to the location of the errno global variable
		 * @return	an integer indicating the success or failure of the syscall, see the BSD documentation for expected values
		 */
		public function read (fileDescriptor:int, bufPtr:int, nbyte:int, errnoPtr:int) : int {
			return nbyte;
		}

		/**
		 * This matches the signature of write from the IKernel interface.
		 * @param	fileDescriptor	The file descriptor being written to
		 * @param	bufPtr	A Pointer to the buffer containing data to be written to this file descriptor.
		 * @param	nbyte	The size of the buffer pointed to by bufPtr
		 * @param	errnoPtr	A pointer to the location of the errno global variable
		 * @return	an integer indicating the success or failure of the syscall, see the BSD documentation for expected values
		 */
		public function write (fileDescriptor:int, bufPtr:int, nbyte:int, errnoPtr:int) : int {
			var str:String = CModule.readString(bufPtr, nbyte);
			if(_logHandler==null){
				trace(str); // or display this string in a textfield somewhere? 
			}else {
				_logHandler(str);
			}
			return nbyte;
		}
	}

}