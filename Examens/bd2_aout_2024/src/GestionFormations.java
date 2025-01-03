import java.sql.*;
import java.util.Scanner;

public class GestionFormations {
    private String url="jdbc:postgresql://*****:*****/*****" +
            "?user=*****&password=*******";
    private PreparedStatement listeParticipants;
    private Connection conn = null;

    public GestionFormations() {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }
        try {
            conn= DriverManager.getConnection(url);
        } catch (SQLException e) {
            System.out.println("Impossible de joindre le server !");
            System.exit(1);
        }
        try {
            listeParticipants = conn.prepareStatement("SELECT id_participant, nom, prenom, niveau" +
                            " FROM examen.vue" +
                            " WHERE nationalite = ? ORDER BY nom, prenom");
        } catch (SQLException e) {
            System.out.println("Erreur avec les requêtes SQL !");
            System.exit(1);
        }
    }

    private void listeParticipants(String nationalite) {
        try {
            listeParticipants.setString(1, nationalite);
            try (ResultSet rs = listeParticipants.executeQuery()) {
                while(rs.next()) {
                    System.out.println("Id_participant : " + rs.getString(1));
                    System.out.println("Nom : " + rs.getString(2));
                    System.out.println("Prénom : " + rs.getString(3));
                    System.out.println("Niveau : " + rs.getString(4));
                    System.out.println();
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
        GestionFormations gf = new GestionFormations();
        Scanner scanner = new Scanner(System.in);
        System.out.print("Entrez une nationalité : ");
        String nationalite = scanner.next();
        System.out.println();
        gf.listeParticipants(nationalite);
        gf.close();
    }
}
