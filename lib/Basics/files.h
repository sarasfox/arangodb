////////////////////////////////////////////////////////////////////////////////
/// @brief file functions
///
/// @file
///
/// DISCLAIMER
///
/// Copyright 2014 ArangoDB GmbH, Cologne, Germany
/// Copyright 2004-2014 triAGENS GmbH, Cologne, Germany
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///     http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///
/// Copyright holder is ArangoDB GmbH, Cologne, Germany
///
/// @author Dr. Frank Celler
/// @author Copyright 2014, ArangoDB GmbH, Cologne, Germany
/// @author Copyright 2011-2013, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

#ifndef ARANGODB_BASICS_C_FILES_H
#define ARANGODB_BASICS_C_FILES_H 1

#ifdef _WIN32
 #include "Basics/win-utils.h"
#endif

#include "Basics/Common.h"
#include "Basics/socket-utils.h"
#include "Basics/vector.h"

// -----------------------------------------------------------------------------
// --SECTION--                                                  public functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief sets close-on-exit for a file
////////////////////////////////////////////////////////////////////////////////

bool TRI_SetCloseOnExitFile (int fileDescriptor);

////////////////////////////////////////////////////////////////////////////////
/// @brief returns the size of a file
///
/// Will return a negative error number on error
////////////////////////////////////////////////////////////////////////////////

int64_t TRI_SizeFile (char const* path);

////////////////////////////////////////////////////////////////////////////////
/// @brief checks if file or directory is writable
////////////////////////////////////////////////////////////////////////////////

bool TRI_IsWritable (char const* path);

////////////////////////////////////////////////////////////////////////////////
/// @brief checks if path is a directory
////////////////////////////////////////////////////////////////////////////////

bool TRI_IsDirectory (char const* path);

////////////////////////////////////////////////////////////////////////////////
/// @brief checks if path is a regular file
////////////////////////////////////////////////////////////////////////////////

bool TRI_IsRegularFile (char const* path);

////////////////////////////////////////////////////////////////////////////////
/// @brief checks if path is a symbolic link
////////////////////////////////////////////////////////////////////////////////

bool TRI_IsSymbolicLink (char const* path);

////////////////////////////////////////////////////////////////////////////////
/// @brief checks if file or directory exists
////////////////////////////////////////////////////////////////////////////////

bool TRI_ExistsFile (char const* path);

////////////////////////////////////////////////////////////////////////////////
/// @brief sets the desired mode on a file, returns errno on error.
////////////////////////////////////////////////////////////////////////////////

int TRI_ChMod (char const* path, long mode, std::string &err);

////////////////////////////////////////////////////////////////////////////////
/// @brief returns the last modification date of a file
////////////////////////////////////////////////////////////////////////////////

int TRI_MTimeFile (char const* path, int64_t* mtime);

////////////////////////////////////////////////////////////////////////////////
/// @brief creates a directory, recursively
////////////////////////////////////////////////////////////////////////////////

int TRI_CreateRecursiveDirectory (char const* path,
                                  long &systemError,
                                  std::string &systemErrorStr);

////////////////////////////////////////////////////////////////////////////////
/// @brief creates a directory
////////////////////////////////////////////////////////////////////////////////

int TRI_CreateDirectory (char const* path,
                         long &systemError,
                         std::string &systemErrorStr);

////////////////////////////////////////////////////////////////////////////////
/// @brief removes an empty directory
////////////////////////////////////////////////////////////////////////////////

int TRI_RemoveEmptyDirectory (char const* filename);

////////////////////////////////////////////////////////////////////////////////
/// @brief removes a directory recursively
////////////////////////////////////////////////////////////////////////////////

int TRI_RemoveDirectory (char const* filename);

////////////////////////////////////////////////////////////////////////////////
/// @brief extracts the dirname
////////////////////////////////////////////////////////////////////////////////

char* TRI_Dirname (char const* path);

////////////////////////////////////////////////////////////////////////////////
/// @brief extracts the basename
////////////////////////////////////////////////////////////////////////////////

char* TRI_Basename (char const* path);

////////////////////////////////////////////////////////////////////////////////
/// @brief creates a filename
////////////////////////////////////////////////////////////////////////////////

char* TRI_Concatenate2File (char const* path, char const* name);

////////////////////////////////////////////////////////////////////////////////
/// @brief creates a filename
////////////////////////////////////////////////////////////////////////////////

char* TRI_Concatenate3File (char const* path1, char const* path2, char const* name);

////////////////////////////////////////////////////////////////////////////////
/// @brief returns a list of files in path
////////////////////////////////////////////////////////////////////////////////

TRI_vector_string_t TRI_FilesDirectory (char const* path);

////////////////////////////////////////////////////////////////////////////////
/// @brief lists the directory tree including files and directories
////////////////////////////////////////////////////////////////////////////////

TRI_vector_string_t TRI_FullTreeDirectory (char const* path);

////////////////////////////////////////////////////////////////////////////////
/// @brief renames a file
////////////////////////////////////////////////////////////////////////////////

int TRI_RenameFile (char const* old,
                    char const* filename,
                    long *systemError = nullptr,
                    std::string *systemErrorStr = nullptr);

////////////////////////////////////////////////////////////////////////////////
/// @brief unlinks a file
////////////////////////////////////////////////////////////////////////////////

int TRI_UnlinkFile (char const* filename);

////////////////////////////////////////////////////////////////////////////////
/// @brief reads into a buffer from a file
////////////////////////////////////////////////////////////////////////////////

bool TRI_ReadPointer (int fd, void* buffer, size_t length);

////////////////////////////////////////////////////////////////////////////////
/// @brief writes buffer to a file
////////////////////////////////////////////////////////////////////////////////

bool TRI_WritePointer (int fd, void const* buffer, size_t length);

////////////////////////////////////////////////////////////////////////////////
/// @brief saves data to a file
////////////////////////////////////////////////////////////////////////////////

int TRI_WriteFile (const char*, const char*, size_t);

////////////////////////////////////////////////////////////////////////////////
/// @brief fsyncs a file
////////////////////////////////////////////////////////////////////////////////

bool TRI_fsync (int fd);

////////////////////////////////////////////////////////////////////////////////
/// @brief slurps in a file
////////////////////////////////////////////////////////////////////////////////

char* TRI_SlurpFile (TRI_memory_zone_t*, char const* filename, size_t* length);

////////////////////////////////////////////////////////////////////////////////
/// @brief creates a lock file based on the PID
///
/// Creates a file containing a the current process identifier and locks
/// that file. Under Unix the call uses the @FN{open} system call with
/// O_EXCL to ensure that the file is created atomically. Then the
/// file is filled with the process identifier as decimal number and a
/// lock on the file is obtained using @FN{flock}.
///
/// On success @ref TRI_ERROR_NO_ERROR is returned.
///
/// Internally, the functions keeps a list of open pid files. Calling the
/// function twice with the same @FA{filename} will succeed and will not
/// create a new entry in this list. The system uses @FN{atexit} to release
/// all open locks upon exit.
////////////////////////////////////////////////////////////////////////////////

int TRI_CreateLockFile (char const* filename);

////////////////////////////////////////////////////////////////////////////////
/// @brief verifies a lock file based on the PID
///
/// The function checks if the file named @FA{filename} exists. If the
/// file exists, then the following checks are performed:
///
/// - Does the file contain a valid decimal number?
/// - Does this number belong to a living process?
/// - Is it possible to lock the file using @FN{flock}. This should failed.
///   If the lock can be obtained, then it is assume that the lock is invalid.
///
/// If the verification returns an error, than @FN{TRI_UnlinkFile} should be
/// used to remove the lock file. If the verification returns @ref
/// TRI_ERROR_NO_ERROR than the file is locked and the lock is valid.
////////////////////////////////////////////////////////////////////////////////

int TRI_VerifyLockFile (char const* filename);

////////////////////////////////////////////////////////////////////////////////
/// @brief releases a lock file based on the PID
////////////////////////////////////////////////////////////////////////////////

int TRI_DestroyLockFile (char const* filename);

////////////////////////////////////////////////////////////////////////////////
/// @brief return the filename component of a file (without path)
////////////////////////////////////////////////////////////////////////////////

char* TRI_GetFilename (char const*);

////////////////////////////////////////////////////////////////////////////////
/// @brief return the absolute path of a file
/// It is the caller's responsibility to free the string created by this
/// function
////////////////////////////////////////////////////////////////////////////////

char* TRI_GetAbsolutePath (char const*, char const*);

////////////////////////////////////////////////////////////////////////////////
/// @brief returns the binary name without any path or suffix
////////////////////////////////////////////////////////////////////////////////

std::string TRI_BinaryName (const char* argv0);

////////////////////////////////////////////////////////////////////////////////
/// @brief locates the directory containing the program
////////////////////////////////////////////////////////////////////////////////

std::string TRI_LocateBinaryPath (char const* argv0);

////////////////////////////////////////////////////////////////////////////////
/// @brief locates the home directory
////////////////////////////////////////////////////////////////////////////////

char* TRI_HomeDirectory (void);

////////////////////////////////////////////////////////////////////////////////
/// @brief calculate the crc32 checksum of a file
////////////////////////////////////////////////////////////////////////////////

int TRI_Crc32File (char const*, uint32_t*);

////////////////////////////////////////////////////////////////////////////////
/// @brief set the application's name
////////////////////////////////////////////////////////////////////////////////

void TRI_SetApplicationName (char const*);

////////////////////////////////////////////////////////////////////////////////
/// @brief get the system's temporary path
////////////////////////////////////////////////////////////////////////////////

char* TRI_GetTempPath (void);

////////////////////////////////////////////////////////////////////////////////
/// @brief get a temporary file name
////////////////////////////////////////////////////////////////////////////////

int TRI_GetTempName (char const*,
                     char**,
                     const bool createFile,
                     long &systemError,
                     std::string &errorMessage);

////////////////////////////////////////////////////////////////////////////////
/// @brief return the user-defined temp path, with a fallback to the system's
/// temp path if none is specified
////////////////////////////////////////////////////////////////////////////////

char* TRI_GetUserTempPath (void);

////////////////////////////////////////////////////////////////////////////////
/// @brief set a new user-defined temp path
////////////////////////////////////////////////////////////////////////////////

void TRI_SetUserTempPath (char*);

////////////////////////////////////////////////////////////////////////////////
/// @brief copies a file from source to dest.
////////////////////////////////////////////////////////////////////////////////

bool TRI_CopyFile (std::string const& src, std::string const& dst, std::string &error);

////////////////////////////////////////////////////////////////////////////////
/// @brief copies the file Attributes from source to dest.
////////////////////////////////////////////////////////////////////////////////

bool TRI_CopyAttributes(std::string srcItem, std::string dstItem, std::string &error);

////////////////////////////////////////////////////////////////////////////////
/// @brief copies the symlink from source to dest; will do nothing in winodws?
////////////////////////////////////////////////////////////////////////////////

bool TRI_CopySymlink(std::string srcItem, std::string dstItem, std::string &error);

////////////////////////////////////////////////////////////////////////////////
/// @brief locate the installation directory
////////////////////////////////////////////////////////////////////////////////

#if _WIN32
std::string TRI_LocateInstallDirectory (void);
#endif

////////////////////////////////////////////////////////////////////////////////
/// @brief locate the configuration directory
////////////////////////////////////////////////////////////////////////////////

char* TRI_LocateConfigDirectory (void);

// -----------------------------------------------------------------------------
// --SECTION--                                                  module functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief initialise the files subsystem
////////////////////////////////////////////////////////////////////////////////

void TRI_InitialiseFiles (void);

////////////////////////////////////////////////////////////////////////////////
/// @brief shutdown the files subsystem
////////////////////////////////////////////////////////////////////////////////

void TRI_ShutdownFiles (void);

#endif

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "/// @brief\\|/// {@inheritDoc}\\|/// @page\\|// --SECTION--\\|/// @\\}"
// End:
