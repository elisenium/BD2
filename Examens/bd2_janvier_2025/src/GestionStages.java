import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Scanner;

public class GestionStages {
    private String url="jdbc:postgresql://172.24.2.6:5432/dbu1s1310" +
            "?user=u1s1310&password=KUEVRR";
    private PreparedStatement vue;
    private Connection conn=null;
    public GestionStages() {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }
        try {
            conn=DriverManager.getConnection(url);
        } catch (SQLException e) {
            System.out.println("Impossible de joindre le server !");
            System.exit(1);
        }
        try {
            vue=
                    conn.prepareStatement("SELECT id_stage, intitule, num_semaine, nbre_inscrits" +
                            " FROM examen.vue" +
                            " WHERE sport = ? ORDER BY num_semaine");
        } catch (SQLException e) {
            System.out.println("Erreur avec les requêtes SQL !");
            System.exit(1);
        }
    }
    private void vue(String sport) {
        try {
            vue.setString(1,sport);
            try (ResultSet rs=vue.executeQuery()) {
                while(rs.next()) {
                    System.out.println();
                    System.out.println("identifiant du stage : " + rs.getInt(1));
                    System.out.println("intitulé : " + rs.getString(2));
                    System.out.println("numéro de semaine : " + rs.getInt(3));
                    System.out.println("nombre d'inscrits : " + rs.getInt(4));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public void close() {
        try {
            conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public static void main(String[] args) {
        GestionStages gs = new GestionStages();
        Scanner scanner = new Scanner(System.in);
        System.out.print("Entrez un sport : ");
        String sport = scanner.next();
        gs.vue(sport);
        gs.close();
    }
}