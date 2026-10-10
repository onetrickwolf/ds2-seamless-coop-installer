// ds2.otw.gg -> serves install.sh from the GitHub repo.
// curl/wget get the script; a browser gets sent to the repo page instead.
const SCRIPT = "https://raw.githubusercontent.com/onetrickwolf/ds2-seamless-coop-installer/main/install.sh";
const REPO = "https://github.com/onetrickwolf/ds2-seamless-coop-installer";

export default {
  async fetch(request) {
    const accept = request.headers.get("accept") || "";
    if (accept.includes("text/html")) {
      return Response.redirect(REPO, 302);
    }
    const upstream = await fetch(SCRIPT, { cf: { cacheTtl: 60, cacheEverything: true } });
    if (!upstream.ok) {
      return new Response("Couldn't fetch the installer from GitHub.\n", { status: 502 });
    }
    return new Response(upstream.body, {
      headers: {
        "content-type": "text/plain; charset=utf-8",
        "cache-control": "public, max-age=60",
      },
    });
  },
};
