////////////////////////////////////////////////////////////////////////////////
//
//  Licensed to the Apache Software Foundation (ASF) under one or more
//  contributor license agreements.  See the NOTICE file distributed with
//  this work for additional information regarding copyright ownership.
//  The ASF licenses this file to You under the Apache License, Version 2.0
//  (the "License"); you may not use this file except in compliance with
//  the License.  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
////////////////////////////////////////////////////////////////////////////////

package mx.utils;

	using StringTools;
	
	import flash.Lib;
    
    /**
     *  The URLUtil class is a static class with methods for working with
     *  full and relative URLs within Flex.
     *  
     *  @see mx.managers.BrowserManager
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    class URLUtil
    {
        //--------------------------------------------------------------------------
        //
        // Private Static Constants
        //
        //--------------------------------------------------------------------------
        
        /**
         *  @private 
         */
        private static inline var SQUARE_BRACKET_LEFT:String = "]";
        private static inline var SQUARE_BRACKET_RIGHT:String = "[";
        private static var SQUARE_BRACKET_LEFT_ENCODED:String = StringTools.urlEncode(SQUARE_BRACKET_LEFT);
        private static var SQUARE_BRACKET_RIGHT_ENCODED:String = StringTools.urlDecode(SQUARE_BRACKET_RIGHT);
        
        //--------------------------------------------------------------------------
        //
        //  Constructor
        //
        //--------------------------------------------------------------------------
        /**
         *  @private
         */
        public function new()
        {
        }
        
        //--------------------------------------------------------------------------
        //
        //  Class methods
        //
        //--------------------------------------------------------------------------
        
        /**
         *  Returns the domain and port information from the specified URL.
         *  
         *  @param url The URL to analyze.
         *  @return The server name and port of the specified URL.
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        public static function getServerNameWithPort(url:String):String
        {
            // Find first slash; second is +1, start 1 after.
            var start:Int = url.indexOf("/") + 2;
            var length:Int = url.indexOf("/", start);
            return length == -1 ? url.substring(start) : url.substring(start, length);
        }
        
        /**
         *  Returns the server name from the specified URL.
         *  
         *  @param url The URL to analyze.
         *  @return The server name of the specified URL.
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        public static function getServerName(url:String):String
        {
            var sp:String = getServerNameWithPort(url);
            
            // If IPv6 is in use, start looking after the square bracket.
            var delim:Int = URLUtil.indexOfLeftSquareBracket(sp);
            delim = (delim > -1)? sp.indexOf(":", delim) : sp.indexOf(":");   
            
            if (delim > 0)
                sp = sp.substring(0, delim);
            return sp;
        }
        
        /**
         *  Returns the port number from the specified URL.
         *  
         *  @param url The URL to analyze.
         *  @return The port number of the specified URL.
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        public static function getPort(url:String):UInt
        {
            var sp:String = getServerNameWithPort(url);
            // If IPv6 is in use, start looking after the square bracket.
            var delim:Int = URLUtil.indexOfLeftSquareBracket(sp);
            delim = (delim > -1)? sp.indexOf(":", delim) : sp.indexOf(":");          
            var port:UInt = 0;
            if (delim > 0)
            {
                var p:Float = Std.parseFloat(sp.substring(delim + 1));
                if (!Math.isNaN(p))
                    port = Std.int(p);
            }
            
            return port;
        }
        
        /**
         *  Converts a potentially relative URL to a fully-qualified URL.
         *  If the URL is not relative, it is returned as is.
         *  If the URL starts with a slash, the host and port
         *  from the root URL are prepended.
         *  Otherwise, the host, port, and path are prepended.
         *
         *  @param rootURL URL used to resolve the URL specified by the <code>url</code> parameter, if <code>url</code> is relative.
         *  @param url URL to convert.
         *
         *  @return Fully-qualified URL.
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        public static function getFullURL(rootURL:String, url:String):String
        {
            if (url != null && !URLUtil.isHttpURL(url))
            {
                if (url.indexOf("./") == 0)
                {
                    url = url.substring(2);
                }
                if (URLUtil.isHttpURL(rootURL))
                {
                    var slashPos:Float;
                    
                    if (url.charAt(0) == '/')
                    {
                        // non-relative path, "/dev/foo.bar".
                        slashPos = rootURL.indexOf("/", 8);
                        if (slashPos == -1)
                            slashPos = rootURL.length;
                    }
                    else
                    {
                        // relative path, "dev/foo.bar".
                        slashPos = rootURL.lastIndexOf("/") + 1;
                        if (slashPos <= 8)
                        {
                            rootURL += "/";
                            slashPos = rootURL.length;
                        }
                    }
                    
                    if (slashPos > 0)
                        url = rootURL.substring(0, Std.int(slashPos)) + url;
                }
            }
            
            return url;
        }
        
        // Note: The following code was copied from Flash Remoting's
        // NetServices client components.
        // It is reproduced here to keep the services APIs
        // independent of the deprecated NetServices code.
        // Note that it capitalizes any use of URL in method or class names.
        
        /**
         *  Determines if the URL uses the HTTP, HTTPS, or RTMP protocol. 
         *
         *  @param url The URL to analyze.
         * 
         *  @return <code>true</code> if the URL starts with "http://", "https://", or "rtmp://".
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        public static function isHttpURL(url:String):Bool
        {
            return url != null &&
                (url.indexOf("http://") == 0 ||
                    url.indexOf("https://") == 0);
        }
        
        /**
         *  Determines if the URL uses the secure HTTPS protocol. 
         *
         *  @param url The URL to analyze.
         * 
         *  @return <code>true</code> if the URL starts with "https://".
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        public static function isHttpsURL(url:String):Bool
        {
            return url != null && url.indexOf("https://") == 0;
        }
        
        /**
         *  Returns the protocol section of the specified URL.
         *  The following examples show what is returned based on different URLs:
         *  
         *  <pre>
         *  getProtocol("https://localhost:2700/") returns "https"
         *  getProtocol("rtmp://www.myCompany.com/myMainDirectory/groupChatApp/HelpDesk") returns "rtmp"
         *  getProtocol("rtmpt:/sharedWhiteboardApp/June2002") returns "rtmpt"
         *  getProtocol("rtmp::1234/chatApp/room_name") returns "rtmp"
         *  </pre>
         *
         *  @param url String containing the URL to parse.
         *
         *  @return The protocol or an empty String if no protocol is specified.
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        public static function getProtocol(url:String):String
        {
            var slash:Int = url.indexOf("/");
            var indx:Int = url.indexOf(":/");
            if (indx > -1 && indx < slash)
            {
                return url.substring(0, indx);
            }
            else
            {
                indx = url.indexOf("::");
                if (indx > -1 && indx < slash)
                    return url.substring(0, indx);
            }
            
            return "";
        }
        
        /**
         *  Replaces the protocol of the
         *  specified URI with the given protocol.
         *
         *  @param uri String containing the URI in which the protocol
         *  needs to be replaced.
         *
         *  @param newProtocol String containing the new protocol to use.
         *
         *  @return The URI with the protocol replaced,
         *  or an empty String if the URI does not contain a protocol.
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        public static function replaceProtocol(uri:String,
                                               newProtocol:String):String
        {
            return uri.replace(getProtocol(uri), newProtocol);
        }
        
        /**
         *  Returns a new String with the port replaced with the specified port.
         *  If there is no port in the specified URI, the port is inserted.
         *  This method expects that a protocol has been specified within the URI.
         *
         *  @param uri String containing the URI in which the port is replaced.
         *  @param newPort uint containing the new port to subsitute.
         *
         *  @return The URI with the new port.
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        public static function replacePort(uri:String, newPort:UInt):String
        {
            var result:String = "";
            
            // First, determine if IPv6 is in use by looking for square bracket
            var indx:Int = uri.indexOf("]");
            
            // If IPv6 is not in use, reset indx to the first colon
            if (indx == -1)
                indx = uri.indexOf(":");
            
            var portStart:Int = uri.indexOf(":", indx+1);
            var portEnd:Int;
            
            // If we have a port
            if (portStart > -1)
            {
                portStart++; // move past the ":"
                portEnd = uri.indexOf("/", portStart);
                //@TODO: need to throw an invalid uri here if no slash was found
                result = uri.substring(0, portStart) +
                    Std.string(newPort) +
                    uri.substring(portEnd, uri.length);
            }
            else
            {
                // Insert the specified port
                portEnd = uri.indexOf("/", indx);
                if (portEnd > -1)
                {
                    // Look to see if we have protocol://host:port/
                    // if not then we must have protocol:/relative-path
                    if (uri.charAt(portEnd+1) == "/")
                        portEnd = uri.indexOf("/", portEnd + 2);
                    
                    if (portEnd > 0)
                    {
                        result = uri.substring(0, portEnd) +
                            ":"+ Std.string(newPort) +
                            uri.substring(portEnd, uri.length);
                    }
                    else
                    {
                        result = uri + ":" + Std.string(newPort);
                    }
                }
                else
                {
                    result = uri + ":"+ Std.string(newPort);
                }
            }
            
            return result;
        }
        
        /**
         *  Returns a new String with the port and server tokens replaced with
         *  the port and server from the currently running application.
         *
         *  @param url String containing the <code>SERVER_NAME_TOKEN</code> and/or <code>SERVER_NAME_PORT</code>
         *  which should be replaced by the port and server from the application.
         *
         *  @return The URI with the port and server replaced.
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        public static function replaceTokens(url:String):String
        {             
			
            var loaderURL:String = Lib.current.loaderInfo.url == null ? "" : Lib.current.loaderInfo.url;
            
            // if the LoaderConfig.url hasn't been configured yet we need to 
            // throw, informing the user that this value must be setup first
            // TODO: add this back in after each new player build
            //if (LoaderConfig.url == null)
            //    trace("WARNING: LoaderConfig.url hasn't been initialized.");
            
            // Replace {server.name}
            if (url.indexOf(SERVER_NAME_TOKEN) > 0)
            {
                loaderURL = URLUtil.replaceEncodedSquareBrackets(loaderURL);
                var loaderProtocol:String = URLUtil.getProtocol(loaderURL);
                var loaderServerName:String = "localhost";
                if (loaderProtocol.toLowerCase() != "file")
                    loaderServerName = URLUtil.getServerName(loaderURL);
                
                url = SERVER_NAME_REGEX.replace(url, loaderServerName);
            }
            
            // Replace {server.port} either with the loader's port, or
            // remove it and the proceeding token if a port is not
            // specified for the SWF Loader.
            var portToken:Int = url.indexOf(SERVER_PORT_TOKEN);
            if (portToken > 0)
            {
                var loaderPort:UInt = URLUtil.getPort(loaderURL);
                if (loaderPort > 0)
                {
                    url = SERVER_PORT_REGEX.replace(url, Std.string(loaderPort));
                }
                else
                {
                    if (url.charAt(portToken - 1) == ":")
                        url = url.substring(0, portToken - 1) + url.substring(portToken);
                    
                    url = SERVER_PORT_REGEX.replace(url, "");
                }
            }
            
            return url;
        }
        
        /**
         * Tests whether two URI Strings are equivalent, ignoring case and
         * differences in trailing slashes.
         * 
         *  @param uri1 The first URI to compare.
         *  @param uri2 The second URI to compare.
         *  
         *  @return <code>true</code> if the URIs are equal. Otherwise, <code>false</code>.
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        public static function urisEqual(uri1:String, uri2:String):Bool
        {
            if (uri1 != null && uri2 != null)
            {
                uri1 = StringTools.trim(uri1).toLowerCase();
                uri2 = StringTools.trim(uri2).toLowerCase();
                
                if (uri1.charAt(uri1.length - 1) != "/")
                    uri1 = uri1 + "/";
                
                if (uri2.charAt(uri2.length - 1) != "/")
                    uri2 = uri2 + "/";
            }
            
            return uri1 == uri2;
        }
        
        /**
         *  Given a url, determines whether the url contains the server.name and
         *  server.port tokens.
         *
         *  @param url A url string. 
         * 
         *  @return <code>true</code> if the url contains server.name and server.port tokens.
         *
         *  @langversion 3.0
         *  @playerversion Flash 10
         *  @playerversion AIR 1.5
         *  @productversion Flex 4
         */ 
        public static function hasTokens(url:String):Bool
        {
            if (url == null || url == "")
                return false;
            if (url.indexOf(SERVER_NAME_TOKEN) > 0)
                return true;
            if (url.indexOf(SERVER_PORT_TOKEN) > 0)
                return true;
            return false;
        }
        
        /**
         * If the <code>LoaderConfig.url</code> property is not available, the <code>replaceTokens()</code> method will not 
         * replace the server name and port properties properly.
         * 
         * @return <code>true</code> if the <code>LoaderConfig.url</code> property is not available. Otherwise, <code>false</code>.
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */  
        public static function hasUnresolvableTokens():Bool
        {
            return Lib.current.loaderInfo.url != null;
        }
        
        /**
         *  The pattern in the String that is passed to the <code>replaceTokens()</code> method that 
         *  is replaced by the application's server name.
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        public static inline var SERVER_NAME_TOKEN:String = "{server.name}";
        
        /**
         *  The pattern in the String that is passed to the <code>replaceTokens()</code> method that 
         *  is replaced by the application's port.
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        public static inline var SERVER_PORT_TOKEN:String = "{server.port}";
        
		private static function indexOfLeftSquareBracket(value:String):Int
        {
            var delim:Int = value.indexOf(SQUARE_BRACKET_LEFT);
            if (delim == -1)
                delim = value.indexOf(SQUARE_BRACKET_LEFT_ENCODED);
            return delim;
        }
		
        private static function replaceEncodedSquareBrackets(value:String):String
        {
            var rightIndex:Int = value.indexOf(SQUARE_BRACKET_RIGHT_ENCODED);
            if (rightIndex > -1)
            {
                value = value.replace(SQUARE_BRACKET_RIGHT_ENCODED, SQUARE_BRACKET_RIGHT);
                var leftIndex:Int = value.indexOf(SQUARE_BRACKET_LEFT_ENCODED);
                if (leftIndex > -1)
                    value = value.replace(SQUARE_BRACKET_LEFT_ENCODED, SQUARE_BRACKET_LEFT);
            }
            return value;
        }
        
        // Reusable reg-exp for token replacement. The . means any char, so this means
        // we should handle server.name and server-name, etc...
        private static var SERVER_NAME_REGEX:EReg = new EReg("\\{server.name\\}", "g");
        private static var SERVER_PORT_REGEX:EReg = new EReg("\\{server.port\\}", "g");    
    }
    
