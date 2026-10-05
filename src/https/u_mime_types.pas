unit u_mime_types;

{$mode ObjFPC}{$H+}

interface

const
  c_app_atom_xml = 'application/atom+xml';
  c_app_EDI_X12 = 'application/EDI-X12';
  c_app_EDIFACT = 'application/EDIFACT';
  c_app_json = 'application/json';
  c_app_javascript = 'application/javascript';
  c_app_octet_stream = 'application/octet-stream';
  c_app_ogg = 'application/ogg';
  c_app_pdf = 'application/pdf';
  c_app_postscript = 'application/postscript';
  c_app_soap_xml = 'application/soap+xml';
  c_app_font_woff = 'application/font-woff';
  c_app_xhtml_xml = 'application/xhtml+xml';
  c_app_xml_dtd = 'application/xml-dtd';
  c_app_xop_xml = 'application/xop+xml';
  c_app_zip = 'application/zip';
  c_app_gzip = 'application/gzip';
  c_app_x_bittorrent = 'application/x-bittorrent';
  c_app_x_tex = 'application/x-tex';
  c_app_xml = 'application/xml';
  c_app_msword = 'application/msword';
  c_app_vnd_ms_excel = 'application/vnd.ms-excel';
  c_app_vnd_ms_powerpoint = 'application/vnd.ms-powerpoint';
  c_app_x_yaml = 'application/x-yaml';
  c_app_vnd_api_json = 'application/vnd.api+json';
  c_app_ld_json = 'application/ld+json';
  c_app_vnd_mozilla_xul_xml = 'application/vnd.mozilla.xul+xml';
  c_app_vnd_android_package_archive = 'application/vnd.android.package-archive';
  c_app_x_tar = 'application/x-tar';
  c_app_x_rar_compressed = 'application/x-rar-compressed';

  c_arr_app : array [0..28] of String=(
        c_app_atom_xml, c_app_EDI_X12, c_app_EDIFACT, c_app_json, c_app_javascript,
        c_app_octet_stream, c_app_ogg, c_app_pdf, c_app_postscript,
        c_app_soap_xml, c_app_font_woff, c_app_xhtml_xml, c_app_xml_dtd,
        c_app_xop_xml, c_app_zip, c_app_gzip, c_app_x_bittorrent, c_app_x_tex,
        c_app_xml, c_app_msword, c_app_vnd_ms_excel, c_app_vnd_ms_powerpoint,
        c_app_x_yaml, c_app_vnd_api_json, c_app_ld_json, c_app_vnd_mozilla_xul_xml,
        c_app_vnd_android_package_archive, c_app_x_tar, c_app_x_rar_compressed
      );

  c_aud_basic = 'audio/basic';
  c_aud_L24 = 'audio/L24';
  c_aud_mp4 = 'audio/mp4';
  c_aud_aac = 'audio/aac';
  c_aud_mpeg = 'audio/mpeg';
  c_aud_ogg = 'audio/ogg';
  c_aud_vorbis = 'audio/vorbis';
  c_aud_x_ms_wma = 'audio/x-ms-wma';
  c_aud_x_ms_wax = 'audio/x-ms-wax';
  c_aud_vnd_rn_realaudio = 'audio/vnd.rn-realaudio';
  c_aud_vnd_wave = 'audio/vnd.wave';
  c_aud_webm = 'audio/webm';
  c_aud_flac = 'audio/flac';
  c_aud_amr = 'audio/amr';
  c_aud_3gpp = 'audio/3gpp';
  c_aud_3gpp2 = 'audio/3gpp2';
  c_aud_x_aiff = 'audio/x-aiff';
  c_aud_x_matroska = 'audio/x-matroska';
  c_aud_x_flac = 'audio/x-flac';
  c_aud_x_wav = 'audio/x-wav';
  c_aud_x_ape = 'audio/x-ape';
  c_aud_x_m4a = 'audio/x-m4a';
  c_aud_x_ogg = 'audio/x-ogg';
  c_aud_x_scpls = 'audio/x-scpls';
  c_aud_x_mpegurl = 'audio/x-mpegurl';
  c_aud_opus = 'audio/opus';

  c_arr_aud : array [0..25] of String=(
        c_aud_basic, c_aud_L24, c_aud_mp4, c_aud_aac, c_aud_mpeg, c_aud_ogg,
        c_aud_vorbis, c_aud_x_ms_wma, c_aud_x_ms_wax, c_aud_vnd_rn_realaudio,
        c_aud_vnd_wave, c_aud_webm, c_aud_flac, c_aud_amr, c_aud_3gpp,
        c_aud_3gpp2, c_aud_x_aiff, c_aud_x_matroska, c_aud_x_flac, c_aud_x_wav,
        c_aud_x_ape, c_aud_x_m4a, c_aud_x_ogg, c_aud_x_scpls, c_aud_x_mpegurl,
        c_aud_opus
      );

  c_img_gif = 'image/gif';
  c_img_jpeg = 'image/jpeg';
  c_img_pjpeg = 'image/pjpeg';
  c_img_png = 'image/png';
  c_img_svg_xml = 'image/svg+xml';
  c_img_tiff = 'image/tiff';
  c_img_vnd_microsoft_icon = 'image/vnd.microsoft.icon';
  c_img_vnd_wap_wbmp = 'image/vnd.wap.wbmp';
  c_img_webp = 'image/webp';
  c_img_heif = 'image/heif';
  c_img_heic = 'image/heic';
  c_img_avif = 'image/avif';

  c_arr_img : array [0..11] of String=(
            c_img_gif, c_img_jpeg, c_img_pjpeg, c_img_png, c_img_svg_xml,
            c_img_tiff, c_img_vnd_microsoft_icon, c_img_vnd_wap_wbmp,
            c_img_webp, c_img_heif, c_img_heic, c_img_avif
      );


  c_txt_cmd = 'text/cmd';
  c_txt_css = 'text/css';
  c_txt_csv = 'text/csv';
  c_txt_html = 'text/html';
  c_txt_plain = 'text/plain';
  c_txt_php = 'text/php';
  c_txt_xml = 'text/xml';
  c_txt_markdown = 'text/markdown';
  c_txt_cache_manifest = 'text/cache-manifest';
  c_txt_x_csharp = 'text/x-csharp';
  c_txt_rtf = 'text/rtf';
  c_txt_vcard = 'text/vcard';
  c_txt_vtt = 'text/vtt';
  c_txt_x_java_source = 'text/x-java-source';
  c_txt_x_python = 'text/x-python';
  c_txt_x_c = 'text/x-c';
  c_txt_x_c__ = 'text/x-c++';
  c_txt_x_perl = 'text/x-perl';
  c_txt_x_r = 'text/x-r';
  c_txt_x_shellscript = 'text/x-shellscript';
  c_txt_x_sql = 'text/x-sql';
  c_txt_x_yaml = 'text/x-yaml';
  c_txt_x_asm = 'text/x-asm';
  c_txt_x_sass = 'text/x-sass';
  c_txt_x_markdown = 'text/x-markdown';
  c_txt_x_handlebars_template = 'text/x-handlebars-template';
  c_txt_x_lua = 'text/x-lua';
  c_txt_x_vue = 'text/x-vue';
  c_txt_x_go = 'text/x-go';
  c_txt_x_rustsrc = 'text/x-rustsrc';

  c_arr_txt : array [0..29] of String=(
            c_txt_cmd, c_txt_css, c_txt_csv, c_txt_html, c_txt_plain, c_txt_php,
            c_txt_xml, c_txt_markdown, c_txt_cache_manifest, c_txt_x_csharp,
            c_txt_rtf, c_txt_vcard, c_txt_vtt, c_txt_x_java_source,
            c_txt_x_python, c_txt_x_c, c_txt_x_c__, c_txt_x_perl, c_txt_x_r,
            c_txt_x_shellscript, c_txt_x_sql, c_txt_x_yaml, c_txt_x_asm,
            c_txt_x_sass, c_txt_x_markdown, c_txt_x_handlebars_template,
            c_txt_x_lua, c_txt_x_vue, c_txt_x_go, c_txt_x_rustsrc
      );


  c_vid_mpeg = 'video/mpeg';
  c_vid_mp4 = 'video/mp4';
  c_vid_ogg = 'video/ogg';
  c_vid_quicktime = 'video/quicktime';
  c_vid_webm = 'video/webm';
  c_vid_x_ms_wmv = 'video/x-ms-wmv';
  c_vid_x_flv = 'video/x-flv';
  c_vid_x_msvideo = 'video/x-msvideo';
  c_vid_3gpp = 'video/3gpp';
  c_vid_3gpp2 = 'video/3gpp2';
  c_vid_x_matroska = 'video/x-matroska';
  c_vid_x_f4v = 'video/x-f4v';
  c_vid_x_m4v = 'video/x-m4v';
  c_vid_h264 = 'video/h264';
  c_vid_h265 = 'video/h265';
  c_vid_avi = 'video/avi';
  c_vid_divx = 'video/divx';
  c_vid_x_vob = 'video/x-vob';
  c_vid_x_anim = 'video/x-anim';
  c_vid_x_sgi_movie = 'video/x-sgi-movie';
  c_vid_x_ms_asf = 'video/x-ms-asf';
  c_vid_x_ogm = 'video/x-ogm';
  c_vid_x_mjpeg = 'video/x-mjpeg';
  c_vid_x_pn_realvideo = 'video/x-pn-realvideo';

  c_arr_vid : array [0..23] of String=(
            c_vid_mpeg, c_vid_mp4, c_vid_ogg, c_vid_quicktime, c_vid_webm,
            c_vid_x_ms_wmv, c_vid_x_flv, c_vid_x_msvideo, c_vid_3gpp,
            c_vid_3gpp2, c_vid_x_matroska, c_vid_x_f4v, c_vid_x_m4v, c_vid_h264,
            c_vid_h265, c_vid_avi, c_vid_divx, c_vid_x_vob, c_vid_x_anim,
            c_vid_x_sgi_movie, c_vid_x_ms_asf, c_vid_x_ogm, c_vid_x_mjpeg,
            c_vid_x_pn_realvideo
      );

implementation

end.

