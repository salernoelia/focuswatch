drop policy "all auth users can do all crud operations" on "public"."experiences";

revoke delete on table "public"."experiences" from "anon";

revoke insert on table "public"."experiences" from "anon";

revoke references on table "public"."experiences" from "anon";

revoke select on table "public"."experiences" from "anon";

revoke trigger on table "public"."experiences" from "anon";

revoke truncate on table "public"."experiences" from "anon";

revoke update on table "public"."experiences" from "anon";

revoke delete on table "public"."experiences" from "authenticated";

revoke insert on table "public"."experiences" from "authenticated";

revoke references on table "public"."experiences" from "authenticated";

revoke select on table "public"."experiences" from "authenticated";

revoke trigger on table "public"."experiences" from "authenticated";

revoke truncate on table "public"."experiences" from "authenticated";

revoke update on table "public"."experiences" from "authenticated";

revoke delete on table "public"."experiences" from "service_role";

revoke insert on table "public"."experiences" from "service_role";

revoke references on table "public"."experiences" from "service_role";

revoke select on table "public"."experiences" from "service_role";

revoke trigger on table "public"."experiences" from "service_role";

revoke truncate on table "public"."experiences" from "service_role";

revoke update on table "public"."experiences" from "service_role";

alter table "public"."experiences" drop constraint "experiences_supervisor_uid_fkey";

alter table "public"."experiences" drop constraint "experiences_test_user_id_fkey";

alter table "public"."experiences" drop constraint "experiences_pkey";

drop index if exists "public"."experiences_pkey";

drop index if exists "public"."ix_experiences_app_id";

drop index if exists "public"."ix_experiences_rating";

drop index if exists "public"."ix_experiences_user_id";

drop table "public"."experiences";

drop sequence if exists "public"."experiences_id_seq";


