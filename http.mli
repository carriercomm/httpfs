open Cohttp
open Cohttp_lwt_unix
open Core.Std

type http_request = Request.t * Cohttp_lwt_body.t
type http_response = Response.t * Cohttp_lwt_body.t

(* Set of the other servers part of this distributed fs. *)
type servers = Uri.t list

(* Standard request handler that respond to an HTTP request. *)
type request_handler = servers -> http_request -> http_response Lwt.t

(* The default port to listen on HTTP if one isn't provided on the command-line *)
val default_port : int

(* Forward some HTTP request to all the other servers of the distributed fs and
collect the responses. If the request was already forwarded to us by a server,
None is return. *)
val forward_to_others :
  servers -> Code.meth -> http_request -> http_response list Lwt.t option

(* Ensure that only one server respond correctly to the forwarded request. *)
val only_one_response : http_response list -> http_response Lwt.t

(* Converts a list of strings into a list of valid Uris representing
the known remote servers. Throws a fatal exception on badly formatted Uris. *)
val format_ips:
  string list -> Uri.t list

(* Delete the file at the specified path. If the HTTP request contains the
'is-directory' header, then the file must be an empty directory. *)
val delete : request_handler

(* Return then content of the file at the specified path. If the file happen to
be a directory, return the list of files with one file per line and a trailing
slash on files which are themselves directories. A client can distinguish a
directory content from a file content by checking the presence or absence of the
'is-directory' header in the HTTP response. *)
val get : request_handler

(* Create an empty file at the specified path. If the HTTP request contains the
'is-directory' header, then the created file is an empty directory. *)
(* See: lock *)
val post : request_handler

(* Write the content of the request body in the file at the specified path. *)
val put : request_handler

(* Lock the path on every server of the distributed fs to ensure the creation of
the file is unique. *)
val lock : request_handler

(* Return the list of known remote servers. *)
val discover : request_handler

(* Tell a remote server that you exist *)
val hello : Conduit_lwt_unix.flow -> request_handler

(* Tell a remote server that we're leaving the cluster*)
val bye : Conduit_lwt_unix.flow -> request_handler

(* Make a server leave the cluster *)
val disconnect : int -> request_handler

(* Callback used by the server to handle the HTTP requests. *)
val callback : port:int -> Conduit_lwt_unix.flow * 'a -> request_handler

(* Starts the server in discovery mode. It'll atttempt to join the cluster by
contacting the one known server, asking it its list of servers and then
registering itself with all the cluster's servers. If it fails to join,
it'll attempt to disconnect cleanly. *)
val discovery_startup: int -> string -> servers Lwt.t

(* Create a server that will listen to the http request, try to handle them and
forward them to the other servers of the distributed fs. *)
val make_server : port:int -> servers -> unit -> unit Lwt.t
