#name "Trackmania Custom API"
#author "Jack Venberg"

#category "Utility"

int PORT = 65432;
string URL = "127.0.0.1";
float CRASH_ACCELERATION = -0.1;

void Main() {
    auto listenSock = Net::Socket();
    listenSock.Listen(URL, PORT);

    while (true) {
        auto clientSocket = listenSock.Accept();
        while (clientSocket is null) {
            @clientSocket = listenSock.Accept();
            yield();
        }
        startnew(SendData, clientSocket);
    }
}

void SendData(ref@ socket) {
    Net::Socket@ clientSocket = cast<Net::Socket>(socket);

    float prevSpeed = 0;
    float prevTime = 0;
    bool crashing = false;
    while (clientSocket.CanRead()) {
        CGameManiaPlanetScriptAPI@ maniaApi = GetManiaScriptAPI();
        CSmScriptPlayer@ scriptApi = GetPlayerScriptAPI();

        auto json = Json::Object();
        json['running'] = !maniaApi.ActiveContext_InGameMenuDisplayed && maniaApi.ActiveContext_MenuFrame == 'Unassigned';
        if (scriptApi !is null && scriptApi.CurrentRaceTime != prevTime) {
            json['running'] = json['running'] && scriptApi.CurrentRaceTime > 0;
            json['acceleration'] = (scriptApi.Speed - prevSpeed) / (scriptApi.CurrentRaceTime - prevTime);
            if (json['acceleration'] < CRASH_ACCELERATION) {
                if (!crashing) {
                    json['crashed'] = true;
                    crashing = true;
                }
            } else if (crashing) {
                crashing = false;
            }
            json['speed'] = scriptApi.Speed;
            json['distance'] = scriptApi.Distance;
            json['time'] = scriptApi.CurrentRaceTime;

            prevSpeed = scriptApi.Speed;
            prevTime = scriptApi.CurrentRaceTime;
        }
        if (!clientSocket.WriteRaw(Json::Write(json) + '\n')) {
            break;
        }
        yield();
    }
    clientSocket.Close();
}

CGameManiaPlanetScriptAPI@ GetManiaScriptAPI() {
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    return app.ManiaPlanetScriptAPI;
}

CSmScriptPlayer@ GetPlayerScriptAPI() {
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    CSmArenaClient@ playground = cast<CSmArenaClient>(app.CurrentPlayground);
    if (playground !is null) {
        if (playground.GameTerminals.Length > 0) {
            CGameTerminal@ terminal = cast<CGameTerminal>(playground.GameTerminals[0]);
            CSmPlayer@ player = cast<CSmPlayer>(terminal.GUIPlayer);
            if (player !is null) {
                return cast<CSmScriptPlayer>(player.ScriptAPI);
            }
        }
    }
    return null;
}
