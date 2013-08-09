/*
 * This file is part of Apparat.
 * 
 * Apparat is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Apparat is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with Apparat. If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (C) 2009 Joa Ebert
 * http://www.joa-ebert.com/
 * 
 */

package  fluidsolver.utils
{
	import com.joa_ebert.apparat.inline.__bytecode;

	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;

	/**
	 * The Memory class is a high-level API for the Alchemy operations.
	 * 
	 * <p>All calls to Memory work without running the optimizer since it
	 * implements the standard behaviour by default as well. This is of course
	 * slow.</p>
	 * 
	 * <p>Calls to the Memory class will be inlined wherever possible. This
	 * means if you access the Memory class using a runtime namespace it will
	 * not be possible for the optimizer to inline the method call. In that
	 * case you will only benifit from the fact that the code inside the Memory
	 * class will be optimized using the Alchemy operations.</p>
	 * 
	 * @author Joa Ebert
	 */
	public final class CustomMemory 
	{
		public function get byteArray():ByteArray {
			return _byteArray;
		}
		
		private var _byteArray:ByteArray;
		
		public function CustomMemory(byteArray:ByteArray) {
			_byteArray = byteArray;
		}
		/**
		 * Selects a ByteArray object as the current memory.
		 * 
		 * @param byteArray The ByteArray object to work with.
		 */
		public function select( byteArray: ByteArray ): void
		{
			_byteArray = byteArray;
		}
		
		/**
		 * Writes a byte to the memory.
		 * 
		 * @param address The address in memory.
		 * @param value The value to write.
		 */
		public function writeByte( value: int, address: int ): void
		{
			__bytecode(
				0xd1,	//GetLocal1
				0xd2,	//GetLocal2
				0x3a,	//SetByte
				0x47	//ReturnVoid
			);
			
			//
			// DCE will remove this parts since a ReturnVoid has happened
			// before.
			//
			// This applies for all the following methods.
			//
			
			_byteArray.position = address;
			_byteArray.writeByte( value );
		}
		
		/**
		 * Writes a short to the memory.
		 * 
		 * @param address The address in memory.
		 * @param value The value to write.
		 */
		public function writeShort( value: int, address: int ): void
		{
			__bytecode( 0xd1, 0xd2, 0x3b, 0x47 );
			
			_byteArray.position = address;
			_byteArray.writeShort( value );
		}
		
		/**
		 * Writes an integer to the memory.
		 * 
		 * @param address The address in memory.
		 * @param value The value to write.
		 */
		public function writeInt(value: int, address: int): void
		{
			__bytecode( 0xd1, 0xd2, 0x3c, 0x47 );
			
			_byteArray.position = address;
			_byteArray.writeInt( value );
		}
		
		/**
		 * Writes a float to the memory.
		 * 
		 * @param address The address in memory.
		 * @param value The value to write.
		 */
		public function writeFloat(value: Number, address: int): void
		{
			__bytecode( 0xd1, 0xd2, 0x3d, 0x47 );
			
			_byteArray.position = address;
			_byteArray.writeFloat( value );
		}
		
		/**
		 * Writes a double to the memory.
		 * 
		 * @param address The address in memory.
		 * @param value The value to write.
		 */
		public function writeDouble(value: Number, address: int): void
		{
			__bytecode( 0xd1, 0xd2, 0x3e, 0x47 );
			
			_byteArray.position = address;
			_byteArray.writeDouble( value );
		}
		
		/**
		 * Reads an unsigned byte from the memory.
		 * 
		 * @param address The address in memory.
		 * @return Unsigned byte at given address in memory.
		 */
		public function readUnsignedByte( address: int ): int
		{
			__bytecode( 0xd1, 0x35, 0x48 );
			
			_byteArray.position = address;
			return _byteArray.readUnsignedByte();
		}
		
		/**
		 * Reads an unsigned short from the memory.
		 * 
		 * @param address The address in memory.
		 * @return Unsigned short at given address in memory.
		 */
		public function readUnsignedShort(address: int): int
		{
			__bytecode(0xd1, 0x36, 0x48);
			
			_byteArray.position = address;
			return _byteArray.readUnsignedShort();
		}
		
		/**
		 * Reads a signed integer from the memory.
		 * 
		 * @param address The address in memory.
		 * @return Signed integer at given address in memory.
		 */
		public function readInt( address: int ): int
		{
			__bytecode( 0xd1, 0x37, 0x48 );
			
			_byteArray.position = address;
			return _byteArray.readInt();
		}
		
		/**
		 * Reads a float from the memory.
		 * 
		 * @param address The address in memory.
		 * @return Float at given address in memory.
		 */
		public function readFloat( address: int ): Number
		{
			__bytecode( 0xd1, 0x38, 0x48 );
			
			_byteArray.position = address;
			return _byteArray.readFloat();
		}
		
		/**
		 * Reads a double from the memory.
		 * 
		 * @param address The address in memory.
		 * @return Double at given address in memory.
		 */
		public function readDouble( address: int ): Number
		{
			__bytecode( 0xd1, 0x39, 0x48 );
			
			_byteArray.position = address;
			return _byteArray.readDouble();
		}
		
		/**
		 * Sign-extension from 1 to 32 bits.
		 * 
		 * @param value The value to extend.
		 * @return The extended value.
		 */
		public function signExtend1( value: int ): int
		{
			__bytecode( 0xd1, 0x50, 0x48 );
			
			if( 0 != ( value & 0x1 ) )
			{
				value &= 0x0;
				value -= 0x1;
			}
			
			return value;
		}
		
		/**
		 * Sign-extension from 8 to 32 bits.
		 * 
		 * @param value The value to extend.
		 * @return The extended value.
		 */
		public function signExtend8( value: int ): int
		{
			__bytecode( 0xd1, 0x51, 0x48 );
		
			if( 0 != ( value & 0x80 ) )
			{
				value &= 0x7f;
				value -= 0x80;
			}
			
			return value;
		}
		
		/**
		 * Sign-extension from 16 to 32 bits.
		 * 
		 * @param value The value to extend.
		 * @return The extended value.
		 */
		public function signExtend16( value: int ): int
		{
			__bytecode( 0xd1, 0x52, 0x48 );
			
			if( 0 != ( value & 0x8000 ) )
			{
				value &= 0x7fff;
				value -= 0x8000;
			}
			
			return value;
		}
	}
}
