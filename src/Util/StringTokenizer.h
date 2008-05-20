/*
 * src/Util/StringTokenizer.h
 *
 * Copyright (C) 2002-2007 Novamente LLC
 * All Rights Reserved
 *
 * Written by Carlos Lopes <dlopes@vettalabs.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License v3 as 
 * published by the Free Software Foundation and including the exceptions
 * at http://opencog.org/wiki/Licenses 
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program; if not, write to:
 * Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#ifndef STRINGBUFFER_H_
#define STRINGBUFFER_H_

#include <string>

namespace Util{

class StringTokenizer {
	
	public:
		
		/**
		 * Constructor and destructor
		 */ 
		StringTokenizer();
		StringTokenizer(const std::string &str, const std::string &delimiter);
		~StringTokenizer();
		
		/**
		 * Getter and setter for the string to be parsed, that is, to extract 
		 * its tokens.  
		 */
		std::string getString();
		void setString(const std::string &str);
		
		/**
		 * Getter and setter for the delimiter to the tokens.
		 */
		const std::string & getDelimiter();
		void setDelimiter(const std::string &str);  
		
		/**
		 * Return the next token from the string. If the end of the string is 
		 * reached the method retuns a empty string "" 
		 */
		const std::string nextToken();
		
		/**
		 * Reset the position pointers to init position.
		 */
		void reset(); 
	
	private:
		std::string str;
		std::string delimiter;
		
		// start/end position pointers
		unsigned int start;
		unsigned int end;
		
		/**
		 * Inform the delimiter size
		 */
		unsigned int delimiterSize();
		 
}; // class	
}  // namespace

#endif /*STRINGBUFFER_H_*/
