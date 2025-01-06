import java.sql.*;
import java.util.Scanner;

public class GestionCommandes {

    private static final String url="jdbc:postgresql://*******:****/******";

    private Connection conn = null;

    private PreparedStatement listeCommandes;
    public GestionCommandes() {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }
        try {
            conn= DriverManager.getConnection(url,"******","*****");
        } catch (SQLException e) {
            System.out.println("Impossible de joindre le server !");
            System.exit(1);
        }
        try{
            listeCommandes=conn.prepareStatement("SELECT nom_client, id_commande, date_commande, nbre_articles_total" +
                    " FROM examen.vue " + "WHERE nom_client = ? " + "ORDER BY date_commande");

        }catch (SQLException e){
            System.out.println("Erreur avec la rêquetes sql !");
            System.exit(1);
        }

    }
    private  void listeCommandes(String nom_client ) {
        try {
            listeCommandes.setString(1, nom_client);
            try (ResultSet rs = listeCommandes.executeQuery()) {
                while (rs.next()) {
                    System.out.println("nom_client : " + rs.getString(1));
                    System.out.println("id_commande : " + rs.getString(2));
                    System.out.println("date_commande : " + rs.getDate(3));
                    System.out.println("nbre_articles_total : " + rs.getInt(4));
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
        GestionCommandes gc = new GestionCommandes();
        Scanner scanner = new Scanner(System.in);
        System.out.print("Entrez le nom du client : ");
        String nomClient = scanner.next();
        System.out.println();
        gc.listeCommandes(nomClient);
        gc.close();
    }

}
