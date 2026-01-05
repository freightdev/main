{ config, lib, pkgs, ... }:

let
  analyzerScript = pkgs.writeScriptBin "conversation-analyzer" ''
    #!${pkgs.python3}/bin/python3
    import duckdb
    import json
    import sys

    def analyze_conversation(db_path, conversation_id):
        conn = duckdb.connect(db_path)

        # Extract conversation
        query = """
        SELECT user_message, assistant_response, timestamp
        FROM conversations
        WHERE conversation_id = ?
        ORDER BY timestamp
        """

        results = conn.execute(query, [conversation_id]).fetchall()

        # Parse intent
        for msg in results:
            print(f"User: {msg[0]}")
            print(f"Assistant: {msg[1]}")
            print(f"Time: {msg[2]}")
            print("---")

        conn.close()

    if __name__ == "__main__":
        analyze_conversation(sys.argv[1], sys.argv[2])
  '';
in
{
  environment.systemPackages = [ analyzerScript ];
}
