namespace PrimeiraAPI.Model
{
    public interface IDeliveriesRepository
    {
        void Add(Deliveries deliveries);

        List<Deliveries> Get();

        Deliveries GetDeliveryByCode(int deliveryId);

        void Delete(int deliveryId);
    }
}
